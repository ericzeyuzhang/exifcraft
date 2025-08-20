# End-to-End Tests

This directory contains end-to-end tests for the exifcraft application.

## Test Structure

- `setup.ts` - Test environment setup and teardown
- `utils.ts` - Helper functions for EXIF data reading and verification
- `dry-run.test.ts` - Tests for dry run functionality
- `exif-verification.test.ts` - Tests for actual EXIF data writing and verification

## Prerequisites

1. **Node.js** and **npm** must be installed

2. **AI Model** must be running (as configured in config.ts)

3. **exiftool-vendored** npm package is used for EXIF data reading (already included in dependencies)

## Running Tests

### Run all E2E tests
```bash
npm run test:e2e
```

### Run specific test file
```bash
npx vitest run --config vitest.e2e.config.ts tests/e2e/dry-run.test.ts
```

### Run tests in watch mode
```bash
npx vitest --config vitest.e2e.config.ts
```

## Test Descriptions

### Dry Run Tests (`dry-run.test.ts`)
- Verifies that dry run mode outputs expected information
- Ensures files are not actually modified during dry run
- Checks that AI processing simulation is shown

### EXIF Verification Tests (`exif-verification.test.ts`)
- Tests actual EXIF data writing to image files
- Verifies that AI-generated content is correctly written to EXIF fields
- Ensures original technical EXIF data is preserved
- Validates that new descriptive fields are added

## Test Data

Tests use images from `tests/images/original/` which are copied to `tests/images/demo/` for testing. The demo directory is cleaned before and after each test.

## Expected EXIF Fields

The tests verify that the following EXIF fields are written:
- **Title fields**: ImageTitle, XPTitle, ObjectName, Title
- **Description fields**: ImageDescription, Description, Caption-Abstract
- **Keywords field**: Keywords

## Troubleshooting

1. **exiftool-vendored not found**: Ensure the npm package is installed (`npm install`)
2. **AI model not responding**: Check that your AI model (e.g., Ollama) is running
3. **Permission errors**: Ensure the test has write permissions to the demo directory
4. **Timeout errors**: Increase timeout in vitest.e2e.config.ts if tests are slow
