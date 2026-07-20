/**
 * Structured logger utility writing logs exclusively to stdout for developer experience.
 */
export class Logger {
  private static formatAndOutputLog(logLevel: string, logMessage: string) {
    const currentTimestamp = new Date().toISOString();
    const formattedLogLine = `[${currentTimestamp}] [${logLevel.toUpperCase()}] ${logMessage}`;

    if (logLevel === 'ERROR') {
      console.error(formattedLogLine);
    } else {
      console.log(formattedLogLine);
    }
  }

  static info(message: string) {
    this.formatAndOutputLog('INFO', message);
  }

  static warn(message: string) {
    this.formatAndOutputLog('WARN', message);
  }

  static error(message: string, executionError?: any) {
    const combinedMessage = executionError
      ? `${message} - ${executionError.stack || executionError.message || executionError}`
      : message;
    this.formatAndOutputLog('ERROR', combinedMessage);
  }

  static debug(message: string) {
    this.formatAndOutputLog('DEBUG', message);
  }
}

