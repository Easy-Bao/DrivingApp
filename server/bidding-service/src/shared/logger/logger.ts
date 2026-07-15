/**
 * Structured logger utility writing logs to stdout and local file pathways in logs/ directory.
 */
import { appendFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';

const serviceName = 'bidding-service';
const logsDirectoryPath = join(process.cwd(), '../../logs', serviceName);

export class Logger {
  private static formatAndSaveLog(logLevel: string, logMessage: string) {
    const currentTimestamp = new Date().toISOString();
    const formattedLogLine = `[${currentTimestamp}] [${logLevel.toUpperCase()}] ${logMessage}\n`;

    // Print output to console stdout
    console.log(formattedLogLine.trim());

    // Persist logs to dedicated service log file
    try {
      if (!existsSync(logsDirectoryPath)) {
        mkdirSync(logsDirectoryPath, { recursive: true });
      }
      const logFilePath = join(logsDirectoryPath, `${serviceName}.log`);
      appendFileSync(logFilePath, formattedLogLine);
    } catch (error) {
      console.error('Failed to append log output to file:', error);
    }
  }

  static info(message: string) {
    this.formatAndSaveLog('INFO', message);
  }

  static warn(message: string) {
    this.formatAndSaveLog('WARN', message);
  }

  static error(message: string, executionError?: any) {
    const combinedMessage = executionError
      ? `${message} - ${executionError.stack || executionError.message || executionError}`
      : message;
    this.formatAndSaveLog('ERROR', combinedMessage);
  }

  static debug(message: string) {
    this.formatAndSaveLog('DEBUG', message);
  }
}
