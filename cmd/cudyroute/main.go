package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"runtime/debug"
	"strings"
	"syscall"

	"cudyroute/internal/cudyroute"
)

func main() {
	runtime.GOMAXPROCS(1)
	debug.SetMemoryLimit(32 << 20)
	debug.SetGCPercent(50)
	args := os.Args[1:]
	if filepath.Base(os.Args[0]) == "cudyroute-rpc" || strings.Contains(os.Args[0], "/rpcd/") {
		args = append([]string{"rpc"}, args...)
	}
	root := os.Getenv("CUDYROUTE_ROOT")
	if root == "" {
		root = "/etc/cudyroute"
	}
	run := os.Getenv("CUDYROUTE_RUN")
	if run == "" {
		run = "/tmp/cudyroute"
	}
	if len(args) == 0 {
		fmt.Println("CudyRoute " + cudyroute.Version + ": daemon | rpc | defaults | parse")
		return
	}
	switch args[0] {
	case "defaults":
		_ = json.NewEncoder(os.Stdout).Encode(cudyroute.Defaults())
	case "parse":
		b, _ := io.ReadAll(io.LimitReader(os.Stdin, cudyroute.MaxDownload+1))
		n, bad, e := cudyroute.ParseSubscription(b, "test")
		if e != nil {
			fail(e)
		}
		_ = json.NewEncoder(os.Stdout).Encode(map[string]any{"nodes": n, "rejected": bad})
	case "rpc":
		if len(args) > 1 && args[1] == "list" {
			fmt.Println(`{"state":{},"save":{"data":""},"subscription":{"data":""},"refresh":{"id":""},"catalogue":{},"updatecheck":{},"rules":{},"check":{"ids":[]},"start":{},"stop":{}}`)
			return
		}
		if len(args) < 3 || args[1] != "call" {
			fail(fmt.Errorf("неизвестный RPC"))
		}
		method := args[2]
		b, _ := io.ReadAll(io.LimitReader(os.Stdin, 1<<20+1))
		if method == "save" || method == "subscription" {
			var obj struct {
				Data string `json:"data"`
			}
			if e := json.Unmarshal(b, &obj); e != nil {
				fail(e)
			}
			b = []byte(obj.Data)
		}
		out, e := cudyroute.Relay(run, method, b)
		if e != nil {
			_ = json.NewEncoder(os.Stdout).Encode(map[string]string{"error": e.Error()})
			return
		}
		fmt.Println(string(out))
	case "cleanup":
		m, e := cudyroute.NewManager(root, run, os.Getenv("CUDYROUTE_CORE"))
		if e != nil {
			fail(e)
		}
		if e = m.Cleanup(); e != nil {
			fail(e)
		}
	case "daemon":
		m, e := cudyroute.NewManager(root, run, os.Getenv("CUDYROUTE_CORE"))
		if e != nil {
			fail(e)
		}
		signals := make(chan os.Signal, 1)
		signal.Notify(signals, syscall.SIGTERM, syscall.SIGINT)
		go func() { <-signals; m.Shutdown(); os.Exit(0) }()
		if e = m.Serve(); e != nil {
			fail(e)
		}
	default:
		fail(fmt.Errorf("неизвестная команда"))
	}
}
func fail(e error) { fmt.Fprintln(os.Stderr, e); os.Exit(1) }
