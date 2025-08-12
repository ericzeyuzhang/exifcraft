#!/usr/bin/env node

import { Command } from 'commander';
import * as path from 'path';
import * as fs from 'fs';
import chalk from 'chalk';
import ora from 'ora';
import { processImages } from '../lib/processor';
import { loadConfig } from '../lib/config';
import { cleanup } from '../lib/exifWriter';
import { CLIOptions, ProcessingJob } from '../types';

const program = new Command();

program
  .name('exifcraft')
  .description('AI-powered EXIF metadata crafting tool for images')
  .version('1.0.0');

program
  .option('-d, --directory <path>', 'Path to image directory')
  .option('-f, --files <paths...>', 'Specify image file paths')
  .option('-c, --config <path>', 'Configuration file path', './config.json')
  .option('-v, --verbose', 'Show verbose output')
  .parse();

const options = program.opts() as CLIOptions;

async function main(): Promise<void> {
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
    
    if (options.verbose) {
      console.log(chalk.blue('Configuration:'));
      console.log(JSON.stringify(config, null, 2));
    }

    // Process images
    const spinner = ora('Processing images...').start();
    
    try {
      const processingJob: ProcessingJob = {
        directory: options.directory,
        files: options.files,
        config: config,
        verbose: options.verbose
      };
      
      await processImages(processingJob);
      
      spinner.succeed(chalk.green('All images processed successfully!'));
      
      // Clean up resources and exit successfully
      await cleanup();
      process.exit(0);
      
    } catch (error) {
      spinner.fail(chalk.red('Error occurred while processing images'));
      throw error;
    }

  } catch (error) {
    console.error(chalk.red('Program execution failed:'), (error as Error).message);
    if (options.verbose) {
      console.error((error as Error).stack);
    }
    
    // Clean up resources before exiting with error
    try {
      await cleanup();
    } catch (cleanupError) {
      if (options.verbose) {
        console.error('Cleanup error:', (cleanupError as Error).message);
      }
    }
    process.exit(1);
  }
}

main();
