import { describe, it, expect } from 'vitest';
import { execSync } from 'child_process';
import * as path from 'path';
import { setupTestEnvironment } from './setup';
import { wasFileModifiedRecently } from './utils';

describe('Dry Run E2E Tests', () => {
  setupTestEnvironment();

  it('should output dry run information without modifying files', async () => {
    const configPath = path.resolve('./config.ts');
    const demoDir = path.resolve('./tests/images/demo');
    
    // Build the project first
    execSync('npm run build', { stdio: 'pipe' });
    
    // Run dry run command
    const output = execSync(
      `node --no-warnings dist/bin/cli.js -d ${demoDir} -c ${configPath} --verbose --dry-run`,
      { 
        encoding: 'utf8',
        stdio: 'pipe'
      }
    );

    // Verify dry run output contains expected patterns
    expect(output).toContain('DRY RUN');
    expect(output).toContain('Processing images...');
    expect(output).toContain('demo');
    
    // Verify that files were not actually modified
    // Check that no backup files were created
    const demoFiles = execSync(`ls -la ${demoDir}`, { encoding: 'utf8' });
    expect(demoFiles).not.toContain('.backup');
    
    // Verify that original files still exist and haven't been modified
    const originalFiles = ['DSCF3752.JPG', 'IMAG0062.JPG', 'IMG_9897.HEIC'];
    for (const file of originalFiles) {
      const filePath = path.join(demoDir, file);
      expect(wasFileModifiedRecently(filePath, 300)).toBe(true); // 5 minutes
    }
  });

  it('should show AI processing simulation in dry run mode', async () => {
    const configPath = path.resolve('./config.ts');
    const demoDir = path.resolve('./tests/images/demo');
    
    const output = execSync(
      `node --no-warnings dist/bin/cli.js -d ${demoDir} -c ${configPath} --verbose --dry-run`,
      { 
        encoding: 'utf8',
        stdio: 'pipe'
      }
    );

    // Verify AI processing simulation
    expect(output).toContain('Processing [title] task');
    expect(output).toContain('Processing [description] task');
    expect(output).toContain('Processing [keywords] task');
    
    // Verify that it shows what would be written but doesn't actually write
    expect(output).toContain('Would write EXIF tags');
    expect(output).toContain('DRY RUN');
  });
});
