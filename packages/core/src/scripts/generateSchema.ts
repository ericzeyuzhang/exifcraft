import { promises as fs } from 'fs';
import * as path from 'path';
import { getConfigJsonSchemaWithMeta } from '../schema';

async function main() {
  const outputDir = path.resolve(process.cwd(), 'dist');
  const outputPath = path.join(outputDir, 'exifcraft-config.schema.json');
  await fs.mkdir(outputDir, { recursive: true });
  const schema = getConfigJsonSchemaWithMeta();
  await fs.writeFile(outputPath, JSON.stringify(schema, null, 2), 'utf-8');
  // eslint-disable-next-line no-console
  console.log(`Wrote JSON Schema to ${outputPath}`);
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});


