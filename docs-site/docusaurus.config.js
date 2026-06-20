// @ts-check

const config = {
  title: 'i3config Documentation',
  url: 'https://kingwill101.github.io',
  baseUrl: '/dart_i3config/',
  favicon: 'img/favicon.svg',
  organizationName: 'kingwill101',
  projectName: 'dart_i3config',
  trailingSlash: false,
  onBrokenLinks: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },
  staticDirectories: ['static'],
  presets: [
    [
      'classic',
      {
        docs: {
          path: '../docs',
          routeBasePath: '/',
          sidebarPath: require.resolve('./sidebars.js'),
          breadcrumbs: true,
          editUrl: undefined,
        },
        blog: false,
        pages: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      },
    ],
  ],
  themeConfig: {
    navbar: {
      title: 'i3config Docs',
    },
    footer: {
      style: 'dark',
      copyright: `Copyright © ${new Date().getFullYear()} i3config.`,
    },
    prism: {
      additionalLanguages: ['dart', 'json'],
    },
  },
};

module.exports = config;
