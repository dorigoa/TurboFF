# TurboFF

Scripts that start and stop TurboFieldfareServer on MacStudio1 (`192.168.1.101`). They are made for
[llm-console](https://github.com/dorigoa/llm-console) (Mac tab, TurboFieldfare card), which runs them
over ssh, and work by hand too.

| Script | What it does |
|---|---|
| `run-turboff.sh` | Starts the server in the background with one `.gturbo` model and returns once `/v1/models` answers. It fails as soon as the server exits, or after `-wait` seconds. |
| `stop.sh` | Stops the server and waits until it has exited: SIGTERM, then SIGKILL after 30 s. Nothing running is not an error. |

```bash
~/TurboFF/run-turboff.sh -model gemma4-8bit -ctx 262144 -host 192.168.1.101 -port 8080
```
```bash
~/TurboFF/stop.sh
```

`run-turboff.sh` takes these options:
- `-model`: `gemma4-8bit` (default), `gemma4` or `qwen36`, from `/Volumes/Home/TurboFieldFareModel/<model>.gturbo`;
- `-ctx`: the context in tokens, 262144 by default;
- `-host`, `-port`: default `127.0.0.1:8080`;
- `-wait`: seconds to wait for the API, 300 by default.

How it runs:
- it checks first that nothing listens on the port (`lsof`);
- the server is `~/.local/bin/TurboFieldfareServer`, run with `--accept-any-model`;
- each start writes its log to `./turboff-<timestamp>.log`, next to the scripts (git ignores the logs).
