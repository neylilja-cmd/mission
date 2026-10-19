{{flutter_js}}
{{flutter_build_config}}

// Flutter 標準のサービスワーカーは非推奨のため使わず、オフライン対応は sw.js で行う。
_flutter.loader.load();

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('sw.js').then(() => navigator.serviceWorker.ready).then((registration) => {
      // 初回起動時は、サービスワーカーが動き出す前に読み込んだファイルがあるので、
      // それらも保存してもらうよう一覧を渡す（次回からオフラインでも開けるように）。
      const sendLoadedFiles = () => {
        if (!registration.active) return;
        const urls = performance.getEntriesByType('resource').map((entry) => entry.name);
        urls.push(location.href);
        registration.active.postMessage({ type: 'cache-urls', urls });
      };
      setTimeout(sendLoadedFiles, 3000);
      setTimeout(sendLoadedFiles, 15000);
    });
  });
}
