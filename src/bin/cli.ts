#!/usr/bin/env node

import { Command } from 'commander';
import * as path from 'path';
import * as fs from 'fs';
import chalk from 'chalk';
import { processImages } from '../lib/processor';
import { loadConfig } from '../lib/configProvider';
import { cleanup } from '../lib/exifWriter';
import { CLIOptions, JobSetting } from '../models';
import { Logger } from '../lib/logger';

const program = new Command();

program
  .name('exifcraft')
  .description('AI-powered EXIF metadata crafting tool for images')
  .version('1.0.0');

program
  .option('-d, --directory <path>', 'Path to image directory')
  .option('-f, --files <paths...>', 'Specify image file paths')
  .option('-c, --config <path>', 'TypeScript configuration file path (.ts)', './config.ts')
  .option('-v, --verbose', 'Show verbose output')
  .option('--dry-run', 'Dry run mode - Simulate behaviors without modifying files')
  .parse();

const options = program.opts() as CLIOptions;

async function main(): Promise<void> {
  // Initialize logger singleton
  const logger = Logger.getInstance({
    verbose: options.verbose,
    dryRun: options.dryRun
  });

  try {
    // Validate input parameters
    if (!options.directory && !options.files) {
      console.error(chalk.red('Error: Must specify image directory (-d) or image files (-f)'));
      process.exit(1);
    }

    // Load configuration file
    const configPath = path.resolve(options.config);
    if (!fs.existsSync(configPath)) {
      console.error(chalk.red(`Error: Configuration file does not exist: ${configPath}`));
      console.log(chalk.yellow('Hint: Please create a configuration file or use the default ./config.json'));
      process.exit(1);
    }

    const config = await loadConfig(configPath);
    
    // Show configuration
    if (options.verbose) {
      console.log(chalk.blue('Configuration:'));
      console.log(JSON.stringify(config, null, 2));
    }

    // Process images
    console.log(chalk.blue('Processing images...'));
    
    try {
      const processingJob: JobSetting = {
        directory: options.directory,
        files: options.files,
        config: config,
        verbose: options.verbose,
        dryRun: options.dryRun
      };
      
      await processImages(processingJob, logger);
      
      // Clean up resources and exit successfully
      await cleanup();
      process.exit(0);
      
    } catch (error) {
      logger.showError('Error occurred while processing images');
      throw error;
    }

  } catch (error) {
    logger.showError('Program execution failed:', error as Error);
    
    // Clean up resources before exiting with error
    try {
      await cleanup();
    } catch (cleanupError) {
      logger.showError('Cleanup error:', cleanupError as Error);
    }
    process.exit(1);
  }
}

main();
