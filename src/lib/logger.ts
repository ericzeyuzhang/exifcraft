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

  // Show progress (used multiple times)
  showProgress(current: number, total: number, fileName: string): void {
    console.log(chalk.yellow(`Processing ${fileName} [${current}/${total}]`));
  }

  // Show AI call information (used multiple times)
  showAICall(endpoint: string, model: string): void {
    if (this.options.verbose) {
      console.log(`    Calling Ollama API: ${endpoint}`);
      console.log(`    Model: ${model}`);
    }
  }

  // Show AI response (used multiple times)
  showAIResponse(response: string): void {
    if (this.options.verbose) {
      console.log(`  AI response: ${response.substring(0, 100)}${response.length > 100 ? '...' : ''}`);
    }
  }

  // Show processing summary (complex logic)
  showSummary(summary: ProcessingSummary): void {
    console.log(chalk.green('\n✔ Processing completed!'));
    
    if (summary.successfulFiles.length > 0) {
      console.log(chalk.green(`\nSuccessfully processed (${summary.successfulFiles.length}):`));
      summary.successfulFiles.forEach(file => {
        console.log(chalk.green(`  ✓ ${file}`));
      });
    }
    
    if (summary.failedFiles.length > 0) {
      console.log(chalk.red(`\nFailed to process (${summary.failedFiles.length}):`));
      summary.failedFiles.forEach(({ fileName, error }) => {
        console.log(chalk.red(`  ✗ ${fileName}: ${error}`));
      });
    }
  }

  // Show error (used multiple times)
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
