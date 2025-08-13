import React, { useState, useEffect } from 'react';
import {
  Box,
  CssBaseline,
  ThemeProvider,
  createTheme,
  AppBar,
  Toolbar,
  Typography,
  Container,
  Paper,
  Grid,
  Alert,
  Snackbar,
  CircularProgress
} from '@mui/material';
import { FileSelector } from './components/FileSelector';
import { ConfigEditor } from './components/ConfigEditor';
import { ProcessingPanel } from './components/ProcessingPanel';
import { ElectronTest } from './components/ElectronTest';
import type { ExifCraftConfig, JobSetting, ProcessingResult, FileItem } from './types';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

// Check if we're running in Electron
const isElectron = typeof window !== 'undefined' && window.electronAPI;

function App() {
  const [config, setConfig] = useState<ExifCraftConfig | null>(null);
  const [selectedFiles, setSelectedFiles] = useState<FileItem[]>([]);
  const [processingStatus, setProcessingStatus] = useState<ProcessingResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success'
  });

  useEffect(() => {
    // Load default config on startup
    loadDefaultConfig();
  }, []);

  const loadDefaultConfig = async () => {
    try {
      setLoading(true);
      setError(null);
      
      if (!isElectron) {
        // Fallback for non-Electron environment (browser testing)
        const defaultConfig: ExifCraftConfig = {
          tasks: [
            {
              name: "title",
              prompt: "Generate a title for this image",
              tags: [
                {
                  name: "ImageTitle",
                  allowOverwrite: true
                }
              ]
            },
            {
              name: "description",
              prompt: "Describe this image",
              tags: [
                {
                  name: "ImageDescription",
                  allowOverwrite: true
                }
              ]
            }
          ],
          aiModel: {
            provider: "ollama",
            endpoint: "http://localhost:11434/api/generate",
            model: "llava",
            options: {
              temperature: 0,
              max_tokens: 500
            }
          },
          imageFormats: [".jpg", ".jpeg", ".png", ".heic"],
          preserveOriginal: false,
          basePrompt: "You are a helpful assistant."
        };
        setConfig(defaultConfig);
      } else {
        const defaultConfig = await window.electronAPI.getDefaultConfig();
        setConfig(defaultConfig);
      }
    } catch (error) {
      console.error('Failed to load default configuration:', error);
      setError('Failed to load default configuration. Please check if Electron is running properly.');
      showSnackbar('Failed to load default configuration', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleFilesSelected = (files: FileItem[]) => {
    setSelectedFiles(files);
  };

  const handleConfigChange = (newConfig: ExifCraftConfig) => {
    setConfig(newConfig);
  };

  const handleProcessImages = async () => {
    if (!config || selectedFiles.length === 0) {
      showSnackbar('Please select files and configure settings first', 'error');
      return;
    }

    const selectedFilePaths = selectedFiles
      .filter(file => file.selected)
      .map(file => file.path);

    if (selectedFilePaths.length === 0) {
      showSnackbar('Please select at least one file to process', 'error');
      return;
    }

    if (!isElectron) {
      showSnackbar('This feature requires Electron environment', 'error');
      return;
    }

    const jobSetting: JobSetting = {
      files: selectedFilePaths,
      config,
      verbose: true,
      dryRun: false
    };

    try {
      setProcessingStatus({ success: false, error: 'Processing...' });
      const result = await window.electronAPI.processImages(jobSetting);
      setProcessingStatus(result);
      
      if (result.success) {
        showSnackbar('Image processing completed successfully!', 'success');
      } else {
        showSnackbar(`Processing failed: ${result.error}`, 'error');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setProcessingStatus({ success: false, error: errorMessage });
      showSnackbar(`Processing failed: ${errorMessage}`, 'error');
    }
  };

  const showSnackbar = (message: string, severity: 'success' | 'error') => {
    setSnackbar({ open: true, message, severity });
  };

  const handleCloseSnackbar = () => {
    setSnackbar(prev => ({ ...prev, open: false }));
  };

  if (loading) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box 
          sx={{ 
            display: 'flex', 
            justifyContent: 'center', 
            alignItems: 'center', 
            height: '100vh',
            flexDirection: 'column',
            gap: 2
          }}
        >
          <CircularProgress />
          <Typography>Loading ExifCraft GUI...</Typography>
        </Box>
      </ThemeProvider>
    );
  }

  if (error) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box sx={{ p: 3 }}>
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
          <Typography variant="body2" color="text.secondary">
            If you're testing in a browser, some features may not work. Please run the application in Electron.
          </Typography>
        </Box>
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ flexGrow: 1 }}>
        <AppBar position="static">
          <Toolbar>
            <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
              ExifCraft - AI-Powered EXIF Metadata Tool
            </Typography>
            {!isElectron && (
              <Typography variant="caption" sx={{ color: 'warning.light' }}>
                Browser Mode (Limited)
              </Typography>
            )}
          </Toolbar>
        </AppBar>

        <Container maxWidth="xl" sx={{ mt: 3, mb: 3 }}>
          <Grid container spacing={3}>
            {/* File Selection */}
            <Grid item xs={12} md={6}>
              <Paper sx={{ p: 3, height: 'fit-content' }}>
                <FileSelector
                  selectedFiles={selectedFiles}
                  onFilesSelected={handleFilesSelected}
                />
              </Paper>
            </Grid>

            {/* Configuration */}
            <Grid item xs={12} md={6}>
              <Paper sx={{ p: 3, height: 'fit-content' }}>
                <ConfigEditor
                  config={config}
                  onConfigChange={handleConfigChange}
                />
              </Paper>
            </Grid>

            {/* Processing Panel */}
            <Grid item xs={12}>
              <Paper sx={{ p: 3 }}>
                <ProcessingPanel
                  selectedFiles={selectedFiles}
                  config={config}
                  processingStatus={processingStatus}
                  onProcessImages={handleProcessImages}
                />
              </Paper>
            </Grid>

            {/* Electron Test */}
            <Grid item xs={12}>
              <ElectronTest />
            </Grid>
          </Grid>
        </Container>

        <Snackbar
          open={snackbar.open}
          autoHideDuration={6000}
          onClose={handleCloseSnackbar}
        >
          <Alert
            onClose={handleCloseSnackbar}
            severity={snackbar.severity}
            sx={{ width: '100%' }}
          >
            {snackbar.message}
          </Alert>
        </Snackbar>
      </Box>
    </ThemeProvider>
  );
}

export default App;
