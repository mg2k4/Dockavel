import { defineConfig, loadEnv } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig(({ command, mode }) => {
    const env = loadEnv(mode, process.cwd(), '');
    const isProduction = command === 'build';

    return {
        plugins: [
            laravel({
                input: [
                    'resources/css/app.css',
                    'resources/js/app.js',
                ],
                refresh: true,
            }),
        ],

        server: isProduction ? {} : {
            host: env.VITE_HOST || '0.0.0.0',
            port: parseInt(env.VITE_PORT || '5173'),
            hmr: {
                host: env.VITE_HMR_HOST || 'localhost',
                port: parseInt(env.VITE_PORT || '5173'),
            },
            watch: {
                // Ignore directories that don't need HMR
                ignored: [
                    '**/vendor/**',
                    '**/storage/**',
                    '**/bootstrap/cache/**',
                    '**/node_modules/**',
                    '**/.git/**',
                ],
            },
        },
    }
});
