import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import federation from '@originjs/vite-plugin-federation';
import { versionTrackerPlugin } from '../../code-common/build-utils/versionTrackerPlugin';

// 微前端子应用 Vite 配置标准模板
// 注意：base 必须设置为 /<module_key>/（末尾带正斜杠），以便 CodeBench 网关在 /<module_key>/assets/remoteEntry.js 正确拉取产物
export default defineConfig({
  plugins: [
    react(),
    versionTrackerPlugin({ appName: 'code-template' }),
    federation({
      name: 'template',
      filename: 'remoteEntry.js',
      exposes: {
        './App': './src/App.tsx',
        './menu': './src/menu.ts',
      },
      shared: ['react', 'react-dom', 'react-router-dom'],
    }),
  ],
  base: process.env.VITE_BASE_PATH || '/template/',
  build: {
    target: 'esnext',
    minify: 'esbuild',
    cssCodeSplit: false,
  },
  server: {
    port: 5180,
    proxy: {
      '/template/api': {
        target: 'http://127.0.0.1:8090',
        changeOrigin: true,
      },
      '/api': {
        target: 'http://127.0.0.1:8090',
        changeOrigin: true,
      },
    },
  },
});
