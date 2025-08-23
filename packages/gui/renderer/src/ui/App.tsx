import React, { useEffect, useMemo, useState } from 'react';
import { ConfigForm } from './ConfigForm';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';

type Progress = { currentIndex: number; total: number; fileName: string };

export const App: React.FC = () => {
  const [directory, setDirectory] = useState<string | null>(null);
  const [configPath, setConfigPath] = useState<string>('');
  const [progress, setProgress] = useState<Progress | null>(null);
  const [logs, setLogs] = useState<string[]>([]);
  const [dryRun, setDryRun] = useState<boolean>(true);
  const [verbose, setVerbose] = useState<boolean>(false);
  const [running, setRunning] = useState<boolean>(false);
  const [images, setImages] = useState<string[]>([]);
  const [configObj, setConfigObj] = useState<any | null>(null);
  const [selected, setSelected] = useState<Set<string>>(new Set());

  useEffect(() => {
    if ((window as any).exifcraft?.onProgress) {
      (window as any).exifcraft.onProgress((p: Progress) => setProgress(p));
    }
  }, []);

  const percent = useMemo(() => {
    if (!progress) return 0;
    if (progress.total === 0) return 0;
    return Math.round((progress.currentIndex / progress.total) * 100);
  }, [progress]);

  const onSelectDir = async () => {
    const d = await (window as any).exifcraft?.selectDirectory?.();
    if (d) setDirectory(d);
  };

  useEffect(() => {
    (async () => {
      if (!directory) return;
      const res = await (window as any).exifcraft?.listImages?.(directory);
      if (res.ok && res.files) {
        setImages(res.files);
        setSelected(new Set());
      }
    })();
  }, [directory]);

  const allowedFormats = useMemo(() => new Set((configObj?.imageFormats as string[] | undefined) || []), [configObj]);

  // When formats change, drop selections that are no longer allowed
  useEffect(() => {
    if (allowedFormats.size === 0) return; // no config yet
    setSelected((prev) => {
      const next = new Set<string>();
      for (const f of prev) {
        const ext = (f.split('.').pop() || '').toLowerCase();
        if (allowedFormats.has(ext)) next.add(f);
      }
      return next;
    });
  }, [allowedFormats]);

  const onRun = async () => {
    if (!directory || !configPath) {
      setLogs((l) => [
        ...l,
        'Please select directory and provide config path before running.'
      ]);
      return;
    }
    setRunning(true);
    setLogs((l) => [...l, 'Starting job...']);
    const files = selected.size > 0 ? Array.from(selected) : undefined;
    const res = await (window as any).exifcraft?.runJob?.({ directory, files, configPath, verbose, dryRun });
    if (!res.ok) {
      setLogs((l) => [...l, `Job failed: ${res.message}`]);
    } else {
      setLogs((l) => [...l, 'Job completed.']);
    }
    setRunning(false);
  };

  return (
    <div className="h-full flex text-sm">
      <aside className="w-80 border-r p-3 space-y-3">
        <div className="font-semibold text-base">Sources</div>
        <Button onClick={onSelectDir} disabled={running}>Select Directory</Button>
        <div className="text-gray-600 break-all">{directory || 'No directory selected'}</div>
        <div className="flex items-center gap-2 flex-wrap">
          <Button variant="secondary" size="sm" onClick={() => {
            const allAllowed = images.filter((p) => {
              const ext = (p.split('.').pop() || '').toLowerCase();
              return allowedFormats.size === 0 || allowedFormats.has(ext);
            });
            setSelected(new Set(allAllowed));
          }}>Select All</Button>
          <Button variant="secondary" size="sm" onClick={() => setSelected(new Set())}>Clear</Button>
        </div>
        <div className="h-64 overflow-auto border rounded p-2 space-y-1">
          {images.map((img) => {
            const ext = (img.split('.').pop() || '').toLowerCase();
            const allowed = allowedFormats.size === 0 || allowedFormats.has(ext);
            return (
              <label key={img} className={`flex items-center gap-2 truncate ${allowed ? '' : 'text-gray-400 opacity-60'}`}>
                <input
                  type="checkbox"
                  disabled={!allowed}
                  checked={selected.has(img)}
                  onChange={(e) => {
                    setSelected((prev) => {
                      const next = new Set(prev);
                      if (e.target.checked) next.add(img); else next.delete(img);
                      return next;
                    });
                  }}
                />
                <span className="truncate">{(img.split(/[\\/]/).pop())}</span>
              </label>
            );
          })}
        </div>
      </aside>
      <main className="flex-1 p-4 space-y-4">
        <h1 className="text-xl font-semibold">ExifCraft GUI</h1>

      <div className="flex items-center gap-3">
        <label>Config Path:&nbsp;</label>
        <Input className="w-[400px]" value={configPath} onChange={(e) => setConfigPath(e.target.value)} placeholder="/path/to/config.json" disabled={running} />
        <Button variant="secondary" size="sm" onClick={async () => {
          const p = await (window as any).exifcraft?.selectConfigFile?.();
          if (p) setConfigPath(p);
        }}>Browse</Button>
        <Button variant="secondary" size="sm" onClick={async () => {
          if (!configPath) return;
          const res = await (window as any).exifcraft?.importConfig?.(configPath);
          if (res.ok && res.config) {
            setConfigObj(res.config);
            setLogs((l) => [...l, 'Config imported.']);
          } else {
            setLogs((l) => [...l, `Import failed: ${res.message}`]);
          }
        }}>Import</Button>
        <Button variant="secondary" size="sm" onClick={async () => {
          if (!configPath) return;
          try {
            if (!configObj) {
              setLogs((l) => [...l, 'No config to export. Please import or edit config first.']);
              return;
            }
            const res = await (window as any).exifcraft?.exportConfig?.({ filePath: configPath, config: configObj });
            if (res.ok) setLogs((l) => [...l, 'Config exported.']);
            else setLogs((l) => [...l, `Export failed: ${res.message}`]);
          } catch (e) {
            setLogs((l) => [...l, `Invalid JSON: ${(e as Error).message}`]);
          }
        }}>Export</Button>
      </div>

      <div className="flex items-center gap-4">
        <label className="flex items-center gap-2">
          <input type="checkbox" checked={dryRun} onChange={(e) => setDryRun(e.target.checked)} disabled={running} /> Dry Run
        </label>
        <label className="flex items-center gap-2">
          <input type="checkbox" checked={verbose} onChange={(e) => setVerbose(e.target.checked)} disabled={running} /> Verbose
        </label>
      </div>

      <div>
        <Button onClick={onRun} disabled={running}>Run</Button>
      </div>

      <div>
        <div className="flex items-center gap-3">
          <div className="w-[400px] h-3 bg-gray-200 relative rounded">
            <div className="absolute inset-y-0 left-0 bg-indigo-600 rounded" style={{ width: `${percent}%` }} />
          </div>
          <span>{percent}%</span>
        </div>
        {progress && (
          <div className="mt-2 text-gray-600">
            Processing {progress.fileName} ({progress.currentIndex}/{progress.total})
          </div>
        )}
      </div>

      <div>
        <h3 className="font-semibold">Config Form</h3>
        <ConfigForm value={configObj} onChange={(v) => {
          setConfigObj(v);
        }} />
      </div>

      <div>
        <h3 className="font-semibold">Logs</h3>
        <div className="h-[200px] overflow-auto bg-gray-50 border rounded p-2">
          {logs.map((l, i) => (
            <div key={i}>{l}</div>
          ))}
        </div>
      </div>
      </main>
    </div>
  );
};


