import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const publicDir = join(root, 'public');

const buildIdPath = join(publicDir, '.last_build_id');
const mainPath = join(publicDir, 'main.dart.js');
const version = existsSync(buildIdPath)
  ? readFileSync(buildIdPath, 'utf8').trim()
  : createHash('sha256').update(readFileSync(mainPath)).digest('hex').slice(0, 32);

if (!/^[a-zA-Z0-9_-]+$/.test(version)) {
  throw new Error(`Unexpected build id: ${version}`);
}

const indexPath = join(publicDir, 'index.html');
let index = readFileSync(indexPath, 'utf8');
const scriptPattern =
  /(<script\s+src="flutter_bootstrap\.js)(?:\?v=[^"]*)?(")/;
if (!scriptPattern.test(index)) {
  throw new Error('Could not find the flutter_bootstrap.js script tag');
}
index = index.replace(scriptPattern, `$1?v=${version}$2`);
writeFileSync(indexPath, index);

const bootstrapPath = join(publicDir, 'flutter_bootstrap.js');
let bootstrap = readFileSync(bootstrapPath, 'utf8');
if (!/main\.dart\.js/.test(bootstrap)) {
  throw new Error('Could not find main.dart.js references in the bootstrap');
}
bootstrap = bootstrap.replace(
  /main\.dart\.js(?:\?v=[^"'`]+)?/g,
  `main.dart.js?v=${version}`,
);
writeFileSync(bootstrapPath, bootstrap);

console.log(`Versioned web entry assets with build ${version}`);
