import { createInterface } from 'node:readline/promises';
import { stdin, stdout } from 'node:process';
import { ProvisionAdminSchema } from '../features/schemas/admin/admin.zod.ts';
import { DrizzleAdminAccountRepository } from '../features/repositories/admin/admin.repository.ts';
import { authPostgresClient } from '../shared/admin.drizzle.ts';

type WritableReadline = ReturnType<typeof createInterface> & {
  _writeToOutput?: (value: string) => void;
};

async function promptForPassword(
  readline: WritableReadline,
  label: string,
): Promise<string> {
  stdout.write(label);
  const originalWrite = readline._writeToOutput?.bind(readline);
  readline._writeToOutput = () => undefined;
  const password = await readline.question('');
  readline._writeToOutput = originalWrite;
  stdout.write('\n');
  return password;
}

async function main(): Promise<void> {
  if (!stdin.isTTY || !stdout.isTTY) {
    throw new Error('Owner provisioning must run in an interactive terminal.');
  }

  const readline = createInterface({ input: stdin, output: stdout, terminal: true });

  try {
    const email = (await readline.question('Owner email: ')).toLowerCase().trim();
    const password = await promptForPassword(readline, 'New password: ');
    const confirmation = await promptForPassword(readline, 'Confirm password: ');

    if (password !== confirmation) {
      throw new Error('Passwords do not match.');
    }

    const input = ProvisionAdminSchema.parse({ email, password });
    const passwordHash = await Bun.password.hash(input.password);
    const result = await new DrizzleAdminAccountRepository()
      .provisionOwner(input.email, passwordHash);

    stdout.write(
      result === 'created'
        ? 'Owner account created.\n'
        : 'Owner password rotated and login lock cleared.\n',
    );
  } finally {
    readline.close();
    await authPostgresClient.end();
  }
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : 'Owner provisioning failed.';
  console.error(message);
  process.exitCode = 1;
});
