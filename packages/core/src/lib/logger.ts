import chalk from 'chalk';

export interface LoggingOptions {
  verbose: boolean;
  dryRun: boolean;
}

export interface ProcessingSummary {
  successfulFiles: string[];
  failedFiles: Array<{fileName: string, error: string}>;
}

export class Logger {
  private static instance: Logger;
  private options: LoggingOptions;

  private constructor(options: LoggingOptions) {
    this.options = options;
  }

  public static getInstance(options?: LoggingOptions): Logger {
    if (!Logger.instance && options) {
      Logger.instance = new Logger(options);
    }
    return Logger.instance;
  }
  
  // Show processing summary
  showSummary(summary: ProcessingSummary): void {
    console.log(chalk.green('\n✔ Processing completed!'));
    
      console.log(chalk.green(`\nSuccess(${summary.successfulFiles.length}):`));
      summary.successfulFiles.forEach(file => {
        console.log(chalk.green(`  ✓ ${file}`));
      });
    
      console.log(chalk.red(`\nFailed (${summary.failedFiles.length}):`));
      summary.failedFiles.forEach(({ fileName, error }) => {
        console.log(chalk.red(`  ✗ ${fileName}: ${error}`));
      });
  }

  // Show error
  showError(message: string, error?: Error): void {
    console.error(chalk.red(message));
    if (error) {
      if (this.options.verbose) {
        console.error(error.stack);
      } else {
        console.error(chalk.red(error.message));
      }
    }
  }
}
