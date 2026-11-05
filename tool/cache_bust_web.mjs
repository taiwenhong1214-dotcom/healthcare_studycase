import { createHash } from 'node:crypto';
import { copyFileSync, existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const publicDir = join(root, 'public');

const buildIdPath = join(publicDir, '.last_build_id');
const mainPath = join(publicDir, 'main.dart.js');
const buildId = existsSync(buildIdPath)
  ? readFileSync(buildIdPath, 'utf8').trim()
  : createHash('sha256').update(readFileSync(mainPath)).digest('hex');

if (!/^[a-zA-Z0-9_-]+$/.test(buildId)) {
  throw new Error(`Unexpected build id: ${buildId}`);
}

let mainJs = readFileSync(mainPath, 'utf8');
const canonicalMainJs = mainJs.replace(
  /"(FontManifest\.json|AssetManifest\.bin\.json)(?:\?v=[^"]*)?"/g,
  '"$1"',
);
const version = createHash('sha256')
  .update(buildId)
  .update(canonicalMainJs)
  .digest('hex')
  .slice(0, 32);

// Point index.html at a fresh bootstrap URL, and the bootstrap at a fresh
// entrypoint URL. Old deployments marked both files as immutable, so changing
// their query strings is what lets an existing browser pick up a new build.
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

// The Flutter engine requests these manifests by fixed names. Version the
// requests inside main.dart.js so a previously cached manifest is bypassed.
const manifestNames =
  /"(?:FontManifest\.json|AssetManifest\.bin\.json)(?:\?v=[^"]*)?"/;
if (!manifestNames.test(mainJs)) {
  throw new Error('Could not find manifest references in main.dart.js');
}
mainJs = mainJs.replace(
  /"(FontManifest\.json|AssetManifest\.bin\.json)(?:\?v=[^"]*)?"/g,
  (_, name) => `"${name}?v=${version}"`,
);
writeFileSync(mainPath, mainJs);

// Fonts were also cached as immutable. Give each font a content-hashed URL
// and point the freshly fetched font manifest at it.
const assetsDir = join(publicDir, 'assets');
const fontManifestPath = join(assetsDir, 'FontManifest.json');
const fontManifest = JSON.parse(readFileSync(fontManifestPath, 'utf8'));

function versionFont(assetPath) {
  const canonical = assetPath.replace(/\.[a-f0-9]{8,64}(?=\.[^./]+$)/, '');
  const sourcePath = join(assetsDir, canonical);
  if (!existsSync(sourcePath)) {
    throw new Error(`Missing font asset: ${canonical}`);
  }

  const hash = createHash('sha256')
    .update(readFileSync(sourcePath))
    .digest('hex')
    .slice(0, 12);
  const extensionIndex = canonical.lastIndexOf('.');
  const versioned =
    `${canonical.slice(0, extensionIndex)}.${hash}` +
    canonical.slice(extensionIndex);
  const targetPath = join(assetsDir, versioned);
  copyFileSync(sourcePath, targetPath);
  return versioned;
}

for (const family of fontManifest) {
  for (const font of family.fonts ?? []) {
    if (typeof font.asset === 'string') {
      font.asset = versionFont(font.asset);
    }
  }
}
writeFileSync(fontManifestPath, JSON.stringify(fontManifest));

console.log(`Versioned web entry assets and fonts with build ${version}`);
