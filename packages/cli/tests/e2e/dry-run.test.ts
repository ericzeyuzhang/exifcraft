import { describe, it, expect } from 'vitest';
import { execSync } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';

describe('Dry Run E2E Tests', () => {  
  it('should perform dry run without modifying files and show correct output', async () => {
    const configPath = path.join(process.cwd(), 'tests/e2e/test-config.ts');
    const demoDir = path.join(process.cwd(), 'tests/images/demo');
    
    // Build the project first
    execSync('npm run build', { stdio: 'pipe' });
    
    // Get original file modification times for all files
    const originalFiles = fs.readdirSync(demoDir);
    const originalStats: { [key: string]: fs.Stats } = {};
    
    for (const file of originalFiles) {
      const filePath = path.join(demoDir, file);
      originalStats[file] = fs.statSync(filePath);
    }
    
    // Run dry run command
    const output = execSync(
      `node --no-warnings dist/cli.js -d ${demoDir} -c ${configPath} --dry-run --verbose`,
      { 
        encoding: 'utf8',
        stdio: 'pipe'
      }
    );
    
    // Verify dry run output contains expected information
    expect(output).toContain('DRY RUN MODE');
    expect(output).toContain('Processing images');
    expect(output).toContain('Found');
    expect(output).toContain('image files');
    
    // Should show completion messages (this is expected in dry run mode)
    expect(output).toContain('Completed:');
    
    // Verify files were not modified (check modification times)
    for (const file of originalFiles) {
      const filePath = path.join(demoDir, file);
      const currentStats = fs.statSync(filePath);
      expect(currentStats.mtime.getTime()).toBe(originalStats[file].mtime.getTime());
    }
  });
});
