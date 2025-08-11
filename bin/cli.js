#!/usr/bin/env node

const { Command } = require('commander');
const path = require('path');
const fs = require('fs');
const chalk = require('chalk');
const ora = require('ora');
const { processImages } = require('../lib/processor');
const { loadConfig } = require('../lib/config');
const { cleanup } = require('../lib/exifWriter');

const program = new Command();

program
  .name('exifcraft')
  .description('AI-powered EXIF metadata crafting tool for images')
  .version('1.0.0');

program
  .option('-d, --directory <path>', 'Path to image directory')
  .option('-f, --files <paths...>', 'Specify image file paths')
  .option('-c, --config <path>', 'Configuration file path', './config.json')
  .option('-m, --model <model>', 'Local AI model name or API endpoint', 'ollama')
  .option('-v, --verbose', 'Show verbose output')
  .parse();

const options = program.opts();

async function main() {
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
      await processImages({
        directory: options.directory,
        files: options.files,
        config: config,
        model: options.model,
        verbose: options.verbose
      });
      
      spinner.succeed(chalk.green('All images processed successfully!'));
      
      // Clean up resources and exit successfully
      await cleanup();
      process.exit(0);
      
    } catch (error) {
      spinner.fail(chalk.red('Error occurred while processing images'));
      throw error;
    }

  } catch (error) {
    console.error(chalk.red('Program execution failed:'), error.message);
    if (options.verbose) {
      console.error(error.stack);
    }
    
    // Clean up resources before exiting with error
    try {
      await cleanup();
    } catch (cleanupError) {
      if (options.verbose) {
        console.error('Cleanup error:', cleanupError.message);
      }
    }
    process.exit(1);
  }
}

main();
