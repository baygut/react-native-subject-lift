const path = require('path');
const {getDefaultConfig, mergeConfig} = require('@react-native/metro-config');

/**
 * Metro configuration
 * https://reactnative.dev/docs/metro
 *
 * @type {import('metro-config').MetroConfig}
 */
const projectRoot = __dirname;
const monorepoRoot = path.resolve(projectRoot, '..');

/**
 * `react-native-subject-lift` is linked as `file:..` → source/build live under the repo root.
 * Metro's default hierarchical lookup walks from `../lib/commonjs/...` up to the **library**
 * `node_modules` and loads a **second** `react` → invalid hook call / `useState` of null.
 *
 * - `disableHierarchicalLookup` + a single `nodeModulesPaths` forces deps from this app only.
 * - `resolveRequest` pins `react` / `react/*` / `react-native` to `example/node_modules` (belt + suspenders).
 */
module.exports = mergeConfig(getDefaultConfig(projectRoot), {
  watchFolders: [monorepoRoot],
  resolver: {
    disableHierarchicalLookup: true,
    nodeModulesPaths: [path.resolve(projectRoot, 'node_modules')],
    resolveRequest: (context, moduleName, platform) => {
      if (
        moduleName === 'react' ||
        moduleName === 'react-native' ||
        moduleName.startsWith('react/')
      ) {
        return {
          type: 'sourceFile',
          filePath: require.resolve(moduleName, {paths: [projectRoot]}),
        };
      }
      return context.resolveRequest(context, moduleName, platform);
    },
  },
});
