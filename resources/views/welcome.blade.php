<!DOCTYPE html>
<html lang="en" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dockavel - Production-Ready Laravel Docker Stack</title>
    <meta name="description" content="Production-ready Docker environment for Laravel 12+ with automated deployment, SSL management, and Cloudflare detection.">

    <!-- Favicon -->
    <link rel="icon" type="image/png" href="/favicon/favicon-96x96.png" sizes="96x96" />
    <link rel="icon" type="image/svg+xml" href="/favicon/favicon.svg" />
    <link rel="shortcut icon" href="/favicon/favicon.ico" />
    <link rel="apple-touch-icon" sizes="180x180" href="/favicon/apple-touch-icon.png" />
    <link rel="manifest" href="/favicon/site.webmanifest" />

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://dockavel.com/">
    <meta property="og:title" content="Dockavel - Production-Ready Laravel Docker Stack">
    <meta property="og:description" content="Deploy Laravel to production in minutes with automated SSL, security hardening, and Docker orchestration. Built from 5+ years of production experience.">
    <meta property="og:image" content="https://dockavel.com/images/logo.png">
    <meta property="og:image:width" content="1024">
    <meta property="og:image:height" content="1024">

    <!-- Twitter -->
    <meta property="twitter:card" content="summary_large_image">
    <meta property="twitter:url" content="https://dockavel.com/">
    <meta property="twitter:title" content="Dockavel - Production-Ready Laravel Docker Stack">
    <meta property="twitter:description" content="Deploy Laravel to production in minutes with automated SSL, security hardening, and Docker orchestration.">
    <meta property="twitter:image" content="https://dockavel.com/images/logo.png">

    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>

    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    colors: {
                        primary: '#FF2D20',
                        secondary: '#2496ED',
                    }
                }
            }
        }
    </script>

    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Fira+Code:wght@400;500&display=swap');

        body {
            font-family: 'Inter', sans-serif;
        }

        code, pre {
            font-family: 'Fira Code', monospace;
        }

        /* Comprehensive Markdown Styling */
        .markdown-content {
            color: #111827;
            line-height: 1.75;
        }

        .dark .markdown-content {
            color: #f3f4f6;
        }

        .markdown-content h1 {
            font-size: 2.25rem;
            font-weight: 700;
            margin-bottom: 1.5rem;
            margin-top: 2rem;
            color: #111827;
            border-bottom: 2px solid #e5e7eb;
            padding-bottom: 0.5rem;
            scroll-margin-top: 140px;
        }

        .dark .markdown-content h1 {
            color: #ffffff;
            border-bottom-color: #374151;
        }

        .markdown-content h2 {
            font-size: 1.875rem;
            font-weight: 600;
            margin-bottom: 1.25rem;
            margin-top: 2rem;
            color: #111827;
            border-bottom: 1px solid #e5e7eb;
            padding-bottom: 0.4rem;
            scroll-margin-top: 140px;
        }

        .dark .markdown-content h2 {
            color: #ffffff;
            border-bottom-color: #374151;
        }

        .markdown-content h3 {
            font-size: 1.5rem;
            font-weight: 600;
            margin-bottom: 1rem;
            margin-top: 1.5rem;
            color: #1f2937;
            scroll-margin-top: 140px;
        }

        .dark .markdown-content h3 {
            color: #f3f4f6;
        }

        .markdown-content h4 {
            font-size: 1.25rem;
            font-weight: 600;
            margin-bottom: 0.75rem;
            margin-top: 1.25rem;
            color: #1f2937;
            scroll-margin-top: 140px;
        }

        .dark .markdown-content h4 {
            color: #f3f4f6;
        }

        .markdown-content h5 {
            font-size: 1.125rem;
            font-weight: 600;
            margin-bottom: 0.5rem;
            margin-top: 1rem;
            color: #1f2937;
            scroll-margin-top: 140px;
        }

        .dark .markdown-content h5 {
            color: #f3f4f6;
        }

        .markdown-content h6 {
            font-size: 1rem;
            font-weight: 600;
            margin-bottom: 0.5rem;
            margin-top: 0.75rem;
            color: #1f2937;
            scroll-margin-top: 140px;
        }

        .dark .markdown-content h6 {
            color: #f3f4f6;
        }

        .markdown-content p {
            margin-bottom: 1.25rem;
            color: #374151;
            line-height: 1.625;
        }

        .dark .markdown-content p {
            color: #d1d5db;
        }

        .markdown-content ul,
        .markdown-content ol {
            margin-bottom: 1.25rem;
            margin-left: 1.5rem;
            color: #374151;
        }

        .dark .markdown-content ul,
        .dark .markdown-content ol {
            color: #d1d5db;
        }

        .markdown-content ul {
            list-style-type: disc;
        }

        .markdown-content ol {
            list-style-type: decimal;
        }

        .markdown-content li {
            line-height: 1.625;
            margin-bottom: 0.5rem;
        }

        .markdown-content li > ul,
        .markdown-content li > ol {
            margin-top: 0.5rem;
            margin-bottom: 0.5rem;
        }

        .markdown-content a {
            color: #FF2D20;
            font-weight: 500;
            transition: all 0.2s;
        }

        .markdown-content a:hover {
            text-decoration: underline;
        }

        .markdown-content strong {
            font-weight: 600;
            color: #111827;
        }

        .dark .markdown-content strong {
            color: #ffffff;
        }

        .markdown-content em {
            font-style: italic;
        }

        .markdown-content code {
            background-color: #f3f4f6;
            color: #ef4444;
            padding: 0.125rem 0.375rem;
            border-radius: 0.25rem;
            font-size: 0.875rem;
            font-weight: 500;
        }

        .dark .markdown-content code {
            background-color: #1f2937;
            color: #f87171;
        }

        .markdown-content pre {
            background-color: #111827;
            color: #f3f4f6;
            border-radius: 0.5rem;
            padding: 1.25rem;
            overflow-x: auto;
            margin-bottom: 1.25rem;
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        }

        .markdown-content pre code {
            background-color: transparent;
            color: #f3f4f6;
            padding: 0;
            font-size: 0.875rem;
        }

        .markdown-content blockquote {
            border-left: 4px solid #FF2D20;
            padding-left: 1.25rem;
            padding-top: 0.5rem;
            padding-bottom: 0.5rem;
            margin-top: 1.25rem;
            margin-bottom: 1.25rem;
            font-style: italic;
            color: #4b5563;
            background-color: #f9fafb;
            border-radius: 0 0.25rem 0.25rem 0;
        }

        .dark .markdown-content blockquote {
            color: #9ca3af;
            background-color: #1f2937;
        }

        .markdown-content hr {
            margin-top: 2rem;
            margin-bottom: 2rem;
            border-color: #d1d5db;
        }

        .dark .markdown-content hr {
            border-color: #374151;
        }

        .markdown-content table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 1.5rem;
            overflow: hidden;
            border-radius: 0.5rem;
            box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
        }

        .markdown-content thead {
            background-color: #1f2937;
        }

        .dark .markdown-content thead {
            background-color: #111827;
        }

        .markdown-content th {
            color: #ffffff;
            padding: 0.75rem;
            text-align: left;
            font-weight: 600;
        }

        .markdown-content tbody tr {
            border-bottom: 1px solid #e5e7eb;
        }

        .dark .markdown-content tbody tr {
            border-bottom-color: #374151;
        }

        .markdown-content tbody tr:hover {
            background-color: #f9fafb;
        }

        .dark .markdown-content tbody tr:hover {
            background-color: #1f2937;
        }

        .markdown-content td {
            padding: 0.75rem;
            color: #374151;
        }

        .dark .markdown-content td {
            color: #d1d5db;
        }

        /* Badges should be inline */
        .markdown-content p img[src*="shields.io"],
        .markdown-content p img[src*="badge"],
        .markdown-content p img[src*="img.shields"] {
            display: inline-block;
            margin-right: 0.25rem;
            margin-top: 0.25rem;
            margin-bottom: 0.25rem;
        }

        /* First paragraph with badges - remove bottom margin */
        .markdown-content p:has(> img[src*="shields.io"]) {
            margin-bottom: 0.5rem;
        }

        .nav-link.active {
            background-color: #FF2D20;
            color: #ffffff;
        }

        /* Hide heading permalink symbols */
        .markdown-content .heading-permalink {
            display: none;
        }

        /* Smooth scroll behavior for anchor links */
        html {
            scroll-behavior: smooth;
        }

        /* Ensure sticky elements stay properly positioned */
        header {
            position: -webkit-sticky;
            position: sticky;
            top: 0;
        }

        nav {
            position: -webkit-sticky;
            position: sticky;
        }

        /* Ensure spacing between elements */
        .markdown-content > *:first-child {
            margin-top: 0;
        }

        .markdown-content > *:last-child {
            margin-bottom: 0;
        }
    </style>
</head>
<body class="bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100 transition-colors duration-200">

    @php
        use Illuminate\Support\Facades\File;
        use League\CommonMark\CommonMarkConverter;
        use League\CommonMark\Environment\Environment;
        use League\CommonMark\Extension\CommonMark\CommonMarkCoreExtension;
        use League\CommonMark\Extension\GithubFlavoredMarkdownExtension;
        use League\CommonMark\Extension\HeadingPermalink\HeadingPermalinkExtension;
        use League\CommonMark\MarkdownConverter;

        // Create environment with GitHub Flavored Markdown
        $environment = new Environment([
            'html_input' => 'allow',
            'allow_unsafe_links' => false,
            'heading_permalink' => [
                'html_class' => 'heading-permalink',
                'id_prefix' => '',
                'apply_id_to_heading' => true,
                'heading_class' => '',
                'fragment_prefix' => '',
                'insert' => 'after',
                'min_heading_level' => 1,
                'max_heading_level' => 6,
                'title' => 'Permalink',
                'symbol' => '',
                'aria_hidden' => true,
            ],
        ]);

        $environment->addExtension(new CommonMarkCoreExtension());
        $environment->addExtension(new GithubFlavoredMarkdownExtension());
        $environment->addExtension(new HeadingPermalinkExtension());

        $converter = new MarkdownConverter($environment);

        $docs = [
            'readme' => [
                'title' => 'Getting Started',
                'icon' => '🚀',
                'file' => base_path('README.md')
            ],
            'installation' => [
                'title' => 'Installation',
                'icon' => '📦',
                'file' => base_path('docs/INSTALLATION.md')
            ],
            'docker' => [
                'title' => 'Docker Architecture',
                'icon' => '🐳',
                'file' => base_path('docs/DOCKER.md')
            ],
            'scripts' => [
                'title' => 'Scripts Reference',
                'icon' => '📜',
                'file' => base_path('docs/SCRIPTS.md')
            ],
            'troubleshooting' => [
                'title' => 'Troubleshooting',
                'icon' => '🔧',
                'file' => base_path('docs/TROUBLESHOOTING.md')
            ],
            'contributing' => [
                'title' => 'Contributing',
                'icon' => '🤝',
                'file' => base_path('docs/CONTRIBUTING.md')
            ],
        ];

        foreach ($docs as $key => &$doc) {
            if (File::exists($doc['file'])) {
                $doc['content'] = $converter->convert(File::get($doc['file']))->getContent();

                // Transform documentation links to tab navigation
                $linkMap = [
                    'docs/INSTALLATION.md' => 'installation',
                    'docs/SCRIPTS.md' => 'scripts',
                    'docs/DOCKER.md' => 'docker',
                    'docs/TROUBLESHOOTING.md' => 'troubleshooting',
                    'docs/CONTRIBUTING.md' => 'contributing',
                    'INSTALLATION.md' => 'installation',
                    'SCRIPTS.md' => 'scripts',
                    'DOCKER.md' => 'docker',
                    'TROUBLESHOOTING.md' => 'troubleshooting',
                    'CONTRIBUTING.md' => 'contributing',
                    '../README.md' => 'readme',
                    'README.md' => 'readme',
                ];

                foreach ($linkMap as $mdFile => $tabKey) {
                    // Handle links with anchors
                    $doc['content'] = preg_replace(
                        '/<a href="' . preg_quote($mdFile, '/') . '#[^"]*"([^>]*)>/',
                        '<a href="#" onclick="showSection(\'' . $tabKey . '\'); return false;"$1>',
                        $doc['content']
                    );
                    // Handle links without anchors
                    $doc['content'] = preg_replace(
                        '/<a href="' . preg_quote($mdFile, '/') . '"([^>]*)>/',
                        '<a href="#" onclick="showSection(\'' . $tabKey . '\'); return false;"$1>',
                        $doc['content']
                    );
                }


                $doc['content'] = str_replace(
                    'public/images/logo.png',
                    'images/logo.png',
                    $doc['content']
                );
                $doc['content'] = preg_replace(
                    '/<a href="LICENSE">/',
                    '<a href="/LICENSE">',
                    $doc['content']
                );
            } else {
                $doc['content'] = '<p class="text-gray-500">Documentation file not found.</p>';
            }
        }
        unset($doc); // Break the reference to avoid bugs
    @endphp

    <!-- Header -->
    <header class="sticky top-0 z-50 bg-white dark:bg-gray-800 shadow-md">
        <div class="container mx-auto px-4 py-4">
            <div class="flex items-center justify-between">
                <div class="flex items-center space-x-3">
                    <img src="/images/logo.png" alt="Dockavel Logo" class="h-16 rounded-lg">
                    <div>
                        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Dockavel</h1>
                        <p class="text-sm text-gray-600 dark:text-gray-400">Laravel Docker Production Stack</p>
                    </div>
                </div>

                <div class="flex items-center space-x-4">
                    <button id="theme-toggle" class="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
                        <svg id="theme-icon-light" class="w-6 h-6 hidden dark:block" fill="currentColor" viewBox="0 0 20 20">
                            <path d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"></path>
                        </svg>
                        <svg id="theme-icon-dark" class="w-6 h-6 block dark:hidden" fill="currentColor" viewBox="0 0 20 20">
                            <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"></path>
                        </svg>
                    </button>

                    <a href="https://github.com/mg2k4/Dockavel" target="_blank" class="flex items-center space-x-2 px-4 py-2 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg hover:bg-gray-800 dark:hover:bg-gray-100 transition-colors">
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                        </svg>
                        <span class="font-medium">GitHub</span>
                    </a>
                </div>
            </div>
        </div>
    </header>

    <!-- Navigation Tabs -->
    <nav class="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 sticky top-[96px] z-40">
        <div class="container mx-auto px-4">
            <div class="flex space-x-1 overflow-x-auto">
                @foreach($docs as $key => $doc)
                    <button onclick="showSection('{{ $key }}')"
                            data-section="{{ $key }}"
                            class="nav-link px-4 py-3 whitespace-nowrap text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-t-lg transition-colors {{ $loop->first ? 'active' : '' }}">
                        <span class="mr-2">{{ $doc['icon'] }}</span>
                        {{ $doc['title'] }}
                    </button>
                @endforeach
            </div>
        </div>
    </nav>

    <!-- Main Content -->
    <main class="container mx-auto px-4 py-8">
        @foreach($docs as $key => $doc)
            <section id="section-{{ $key }}" class="doc-section {{ $loop->first ? '' : 'hidden' }}">
                <div class="max-w-5xl mx-auto">
                    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8 md:p-12">
                        <div class="markdown-content">
                            {!! $doc['content'] !!}
                        </div>
                    </div>
                </div>
            </section>
        @endforeach
    </main>

    <!-- Footer -->
    <footer class="bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 mt-16">
        <div class="container mx-auto px-4 py-8">
            <div class="flex flex-col md:flex-row justify-between items-center space-y-4 md:space-y-0">
                <div class="flex items-center space-x-4">
                    <a href="https://laravel.com" target="_blank" class="flex items-center space-x-2 text-gray-600 dark:text-gray-400 hover:text-primary transition-colors">
                        <svg class="w-6 h-6" viewBox="0 0 50 52" fill="currentColor">
                            <path d="M49.626 11.564a.809.809 0 01.028.209v10.972a.8.8 0 01-.402.694l-9.209 5.302V39.25c0 .286-.152.55-.4.694L20.42 51.01c-.044.025-.092.041-.14.058-.018.006-.035.017-.054.022a.805.805 0 01-.41 0c-.022-.006-.042-.018-.063-.026-.044-.016-.09-.03-.132-.054L.402 39.944A.801.801 0 010 39.25V6.334c0-.072.01-.142.028-.210.006-.023.02-.044.028-.067.015-.042.029-.085.051-.124.015-.026.037-.047.055-.071.023-.032.044-.065.071-.093.023-.023.053-.04.079-.06.029-.024.055-.05.088-.069h.001l9.61-5.533a.802.802 0 01.8 0l9.61 5.533h.002c.032.02.059.045.088.068.026.02.055.038.078.06.028.029.048.062.072.094.017.024.04.045.054.071.023.04.036.082.052.124.008.023.022.044.028.068a.809.809 0 01.028.209v20.559l8.008-4.611v-10.51c0-.07.01-.141.028-.208.007-.024.02-.045.028-.068.016-.042.03-.085.052-.124.015-.026.037-.047.054-.071.024-.032.044-.065.072-.093.023-.023.052-.04.078-.06.03-.024.056-.05.088-.069h.001l9.611-5.533a.801.801 0 01.8 0l9.61 5.533c.034.02.06.045.09.068.025.02.054.038.077.06.028.029.048.062.072.094.018.024.04.045.054.071.023.039.036.082.052.124.009.023.022.044.028.068zm-1.574 10.718v-9.124l-3.363 1.936-4.646 2.675v9.124l8.01-4.611zm-9.61 16.505v-9.13l-4.57 2.61-13.05 7.448v9.216l17.62-10.144zM1.602 7.719v31.068L19.22 48.93v-9.214l-9.204-5.209-.003-.002-.004-.002c-.031-.018-.057-.044-.086-.066-.025-.02-.054-.036-.076-.058l-.002-.003c-.026-.025-.044-.056-.066-.084-.02-.027-.044-.05-.06-.078l-.001-.003c-.018-.03-.029-.066-.042-.1-.013-.03-.03-.058-.038-.09v-.001c-.01-.038-.012-.078-.016-.117-.004-.03-.012-.06-.012-.09v-.002-21.481L4.965 9.654 1.602 7.72zm8.81-5.994L2.405 6.334l8.005 4.609 8.006-4.61-8.006-4.608zm4.164 28.764l4.645-2.674V7.719l-3.363 1.936-4.646 2.675v20.096l3.364-1.937zM39.243 7.164l-8.006 4.609 8.006 4.609 8.005-4.61-8.005-4.608zm-.801 10.605l-4.646-2.675-3.363-1.936v9.124l4.645 2.674 3.364 1.937v-9.124zM20.02 38.33l11.743-6.704 5.87-3.35-8-4.606-9.211 5.303-8.395 4.833 7.993 4.524z"/>
                        </svg>
                        <span class="text-sm font-medium">Powered by Laravel</span>
                    </a>

                    <a href="https://www.docker.com" target="_blank" class="flex items-center space-x-2 text-gray-600 dark:text-gray-400 hover:text-secondary transition-colors">
                        <svg class="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M13.983 11.078h2.119a.186.186 0 00.186-.185V9.006a.186.186 0 00-.186-.186h-2.119a.185.185 0 00-.185.185v1.888c0 .102.083.185.185.185m-2.954-5.43h2.118a.186.186 0 00.186-.186V3.574a.186.186 0 00-.186-.185h-2.118a.185.185 0 00-.185.185v1.888c0 .102.082.185.185.185m0 2.716h2.118a.187.187 0 00.186-.186V6.29a.186.186 0 00-.186-.185h-2.118a.185.185 0 00-.185.185v1.887c0 .102.082.186.185.186m-2.93 0h2.12a.186.186 0 00.184-.186V6.29a.185.185 0 00-.185-.185H8.1a.185.185 0 00-.185.185v1.887c0 .102.083.186.185.186m-2.964 0h2.119a.186.186 0 00.185-.186V6.29a.185.185 0 00-.185-.185H5.136a.186.186 0 00-.186.185v1.887c0 .102.084.186.186.186m5.893 2.715h2.118a.186.186 0 00.186-.185V9.006a.186.186 0 00-.186-.186h-2.118a.185.185 0 00-.185.185v1.888c0 .102.082.185.185.185m-2.93 0h2.12a.185.185 0 00.184-.185V9.006a.185.185 0 00-.184-.186h-2.12a.185.185 0 00-.184.185v1.888c0 .102.083.185.185.185m-2.964 0h2.119a.185.185 0 00.185-.185V9.006a.185.185 0 00-.184-.186h-2.12a.186.186 0 00-.186.186v1.887c0 .102.084.185.186.185m-2.92 0h2.12a.185.185 0 00.184-.185V9.006a.185.185 0 00-.184-.186h-2.12a.185.185 0 00-.184.185v1.888c0 .102.082.185.185.185M23.763 9.89c-.065-.051-.672-.51-1.954-.51-.338 0-.676.03-1.01.09-.548-1.534-1.976-2.613-3.61-2.613-.668 0-1.323.16-1.91.47a.185.185 0 00-.058.285c.035.06.106.086.166.067.197-.065.406-.1.62-.1.001 0 .002 0 .003 0 1.057 0 2.004.674 2.335 1.663.033.099.013.206-.05.291a.336.336 0 01-.221.119c-.268.021-.534.055-.797.1a.185.185 0 00-.155.144c-.014.06.008.123.057.162a3.35 3.35 0 011.432 2.755c0 1.849-1.503 3.352-3.352 3.352H1.006a1.006 1.006 0 01-1.006-1.006c0-.556.455-1.006 1.006-1.006h13.255c.185 0 .185-.185.185-.185V9.006c0-.185-.185-.185-.185-.185H8.1c-.185 0-.185.185-.185.185v2.715c0 .185-.185.185-.185.185H5.136c-.185 0-.185-.185-.185-.185V9.006c0-.185-.186-.185-.186-.185H2.182c-.185 0-.186.185-.186.185v2.715c0 .102-.082.185-.185.185h-.37c-.185 0-.185-.185-.185-.185V9.006c0-.185-.185-.185-.185-.185h-1.89a.185.185 0 00-.186.185v1.887c0 .102.083.185.186.185h.37c.102 0 .185.083.185.185v1.888c0 .102-.083.185-.185.185H.37A.185.185 0 00.185 13.78V12.9c0-.102-.083-.185-.185-.185h-.37A.185.185 0 00-.186 12.9v1.888c0 .102.083.185.185.185h.37c.102 0 .185-.083.185-.185v-.555c0-.102.083-.185.185-.185h.926c.185 0 .185.185.185.185v.555c0 .102-.083.185-.185.185h-.556c-.102 0-.185.083-.185.185v.37c0 .102.083.185.185.185h.37c.102 0 .185-.083.185-.185v-.37c0-.102.083-.185.185-.185h1.112c.102 0 .185.083.185.185v.37c0 .102-.083.185-.185.185h-.926a.185.185 0 00-.185.185v.37c0 .102.083.185.185.185h.556c.102 0 .185-.083.185-.185v-.185c0-.102.083-.185.185-.185h14.075c2.4 0 4.352-1.952 4.352-4.352 0-1.03-.36-2.007-1.013-2.778z"/>
                        </svg>
                        <span class="text-sm font-medium">Built with Docker</span>
                    </a>
                </div>

                <div class="text-center text-sm text-gray-600 dark:text-gray-400">
                    <p>&copy; 2026 Dockavel. Released under MIT License.</p>
                    <p class="mt-1">Made with ❤️ for the Laravel community</p>
                </div>

                <div class="flex space-x-4">
                    <a href="https://github.com/mg2k4/Dockavel/issues" target="_blank" class="text-gray-600 dark:text-gray-400 hover:text-primary transition-colors">
                        <span class="text-sm font-medium">Issues</span>
                    </a>
                    <a href="https://github.com/mg2k4/Dockavel/discussions" target="_blank" class="text-gray-600 dark:text-gray-400 hover:text-primary transition-colors">
                        <span class="text-sm font-medium">Discussions</span>
                    </a>
                </div>
            </div>
        </div>
    </footer>

    <script>
        // Theme Toggle
        const themeToggle = document.getElementById('theme-toggle');
        const html = document.documentElement;

        // Check for saved theme preference or default to 'light'
        const currentTheme = localStorage.getItem('theme') || 'light';
        html.classList.toggle('dark', currentTheme === 'dark');

        themeToggle.addEventListener('click', () => {
            html.classList.toggle('dark');
            const theme = html.classList.contains('dark') ? 'dark' : 'light';
            localStorage.setItem('theme', theme);
        });

        // Section Navigation
        function showSection(sectionId) {
            // Hide all sections
            document.querySelectorAll('.doc-section').forEach(section => {
                section.classList.add('hidden');
            });

            // Remove active class from all nav links
            document.querySelectorAll('.nav-link').forEach(link => {
                link.classList.remove('active');
            });

            // Show selected section
            document.getElementById('section-' + sectionId).classList.remove('hidden');

            // Add active class to clicked nav link
            document.querySelector(`[data-section="${sectionId}"]`).classList.add('active');

            // Scroll to top - use setTimeout to ensure content is rendered first
            setTimeout(() => {
                window.scrollTo({ top: 0, behavior: 'smooth' });
            }, 0);
        }

        // Syntax Highlighting
        document.addEventListener('DOMContentLoaded', () => {
            document.querySelectorAll('pre code').forEach((block) => {
                hljs.highlightElement(block);
            });
        });
    </script>
</body>
</html>
