//go:build windows

package main

import (
	"bytes"
	"context"
	_ "embed"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"sync/atomic"
	"syscall"
	"time"
)

//go:embed assets/index.html
var embeddedHTML []byte

//go:embed assets/favicon.ico
var embeddedIcon []byte

const heartbeatSnippet = `<script>
(function(){
  setInterval(function(){ fetch('/__ping', {cache:'no-store'}).catch(function(){}); }, 2000);
  window.addEventListener('beforeunload', function(){
    if (navigator.sendBeacon) navigator.sendBeacon('/__bye');
  });
})();
</script></body>`

func findAppBrowser() (exePath string, profileName string) {
	progFiles := os.Getenv("ProgramFiles")
	progFilesX86 := os.Getenv("ProgramFiles(x86)")
	localAppData := os.Getenv("LocalAppData")

	candidates := []struct {
		path    string
		profile string
	}{
		{filepath.Join(progFilesX86, "Microsoft", "Edge", "Application", "msedge.exe"), "edge-profile"},
		{filepath.Join(progFiles, "Microsoft", "Edge", "Application", "msedge.exe"), "edge-profile"},
		{filepath.Join(progFiles, "Google", "Chrome", "Application", "chrome.exe"), "chrome-profile"},
		{filepath.Join(progFilesX86, "Google", "Chrome", "Application", "chrome.exe"), "chrome-profile"},
		{filepath.Join(localAppData, "Google", "Chrome", "Application", "chrome.exe"), "chrome-profile"},
		{filepath.Join(progFiles, "BraveSoftware", "Brave-Browser", "Application", "brave.exe"), "brave-profile"},
	}

	for _, c := range candidates {
		if c.path != "" {
			if st, err := os.Stat(c.path); err == nil && !st.IsDir() {
				return c.path, c.profile
			}
		}
	}
	for _, bin := range []string{"msedge.exe", "chrome.exe"} {
		if p, err := exec.LookPath(bin); err == nil {
			return p, "browser-profile"
		}
	}
	return "", ""
}

func main() {
	// Serve embedded game on an ephemeral loopback port
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return
	}
	port := ln.Addr().(*net.TCPAddr).Port
	gameURL := fmt.Sprintf("http://127.0.0.1:%d/", port)

	var lastPing atomic.Int64
	lastPing.Store(time.Now().Unix())
	closedCh := make(chan struct{}, 1)

	pageHTML := bytes.Replace(embeddedHTML, []byte("</body>"), []byte(heartbeatSnippet), 1)

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" && r.URL.Path != "/index.html" {
			http.NotFound(w, r)
			return
		}
		lastPing.Store(time.Now().Unix())
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Header().Set("Cache-Control", "no-store")
		_, _ = w.Write(pageHTML)
	})
	mux.HandleFunc("/favicon.ico", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "image/x-icon")
		w.Header().Set("Cache-Control", "public, max-age=86400")
		_, _ = w.Write(embeddedIcon)
	})
	mux.HandleFunc("/__ping", func(w http.ResponseWriter, r *http.Request) {
		lastPing.Store(time.Now().Unix())
		w.WriteHeader(http.StatusNoContent)
	})
	mux.HandleFunc("/__bye", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNoContent)
		select {
		case closedCh <- struct{}{}:
		default:
		}
	})

	srv := &http.Server{Handler: mux}
	go func() {
		_ = srv.Serve(ln)
	}()
	defer func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		_ = srv.Shutdown(ctx)
	}()

	browserExe, profileName := findAppBrowser()
	if browserExe != "" {
		baseData := os.Getenv("LocalAppData")
		if baseData == "" {
			baseData = os.TempDir()
		}
		profileDir := filepath.Join(baseData, "JackAttack64", profileName)
		_ = os.MkdirAll(profileDir, 0o755)

		cmd := exec.Command(
			browserExe,
			"--app="+gameURL,
			"--window-size=900,760",
			"--user-data-dir="+profileDir,
			"--no-first-run",
			"--no-default-browser-check",
			"--disable-features=Translate",
		)
		cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
		if err := cmd.Start(); err == nil {
			done := make(chan error, 1)
			go func() { done <- cmd.Wait() }()
			select {
			case <-done:
				return
			case <-closedCh:
				time.Sleep(300 * time.Millisecond)
				return
			}
		}
	}

	// Fallback: open in default browser (e.g. Firefox) and keep serving while tab is open
	openCmd := exec.Command("rundll32", "url.dll,FileProtocolHandler", gameURL)
	openCmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	_ = openCmd.Start()

	// Wait for initial load, then exit cleanly once the game tab is closed
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()
	started := time.Now()
	for {
		select {
		case <-closedCh:
			time.Sleep(500 * time.Millisecond)
			return
		case <-ticker.C:
			if time.Since(started) > 15*time.Second && time.Now().Unix()-lastPing.Load() > 7 {
				return
			}
		}
	}
}
