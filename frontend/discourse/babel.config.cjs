const { buildMacros } = require("@embroider/macros/babel");
const StripTestSelectors = require("strip-test-selectors");

const macros = buildMacros({
  configure(macrosConfig) {
    macrosConfig.setGlobalConfig(__filename, "@embroider/core", {
      active: true,
    });
  },
});

const PRODUCTION = process.env.EMBER_ENV === "production";

// System tests can run against a production build for speed, but they rely on
// dev-only test affordances that are otherwise stripped from production: the
// `data-test-*` selectors specs query, and the `rails-testing` initializer that
// defines `window.clientSettled`. KEEP_TEST_CODE=1 retains those while
// preserving every other production optimization (minification, tree-shaking,
// @ember/debug stripping).
const KEEP_TEST_CODE = process.env.KEEP_TEST_CODE === "1";
const STRIP_TEST_SELECTORS = PRODUCTION && !KEEP_TEST_CODE;

module.exports = {
  plugins: [
    [
      "babel-plugin-ember-template-compilation",
      {
        compilerPath: "ember-source/ember-template-compiler/index.js",
        enableLegacyModules: [
          "ember-cli-htmlbars",
          "ember-cli-htmlbars-inline-precompile",
          "htmlbars-inline-precompile",
        ],
        transforms: [
          ...macros.templateMacros,
          ...(STRIP_TEST_SELECTORS ? [StripTestSelectors] : []),
        ],
      },
    ],
    [
      "module:decorator-transforms",
      {
        runtime: {
          import: require.resolve("decorator-transforms/runtime-esm"),
        },
      },
    ],
    [
      "@babel/plugin-transform-runtime",
      {
        absoluteRuntime: __dirname,
        useESModules: true,
        regenerator: false,
      },
    ],
    [
      require.resolve("babel-plugin-debug-macros"),
      {
        flags: [
          {
            source: "@glimmer/env",
            flags: {
              DEBUG: !PRODUCTION,
              CI: !!process.env.CI,
              // Retain the `rails-testing` initializer (which defines
              // `window.clientSettled`) in system-test production builds; it is
              // stripped from real production builds like the rest of DEBUG.
              RAILS_TESTING: !PRODUCTION || KEEP_TEST_CODE,
            },
          },
        ],
        debugTools: {
          // Keep `@ember/debug` assertions and deprecations in system-test
          // production builds so client-side failures stay legible and specs
          // asserting on deprecations keep working. It is negligible cost at
          // system-test scale, and stripped from real production builds.
          isDebug: !PRODUCTION || KEEP_TEST_CODE,
          source: "@ember/debug",
          assertPredicateIndex: 1,
        },
        externalizeHelpers: {
          module: "@ember/debug",
        },
      },
      "@ember/debug stripping",
    ],
    ...macros.babelMacros,
  ],

  generatorOpts: {
    compact: false,
  },
};
