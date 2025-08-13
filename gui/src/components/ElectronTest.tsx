import React, { useState, useEffect } from 'react';
import { Box, Typography, Button, Alert, Paper } from '@mui/material';

export const ElectronTest: React.FC = () => {
  const [electronStatus, setElectronStatus] = useState<{
    isElectron: boolean;
    hasAPI: boolean;
    apiMethods: string[];
    error?: string;
  }>({
    isElectron: false,
    hasAPI: false,
    apiMethods: []
  });

  useEffect(() => {
    const checkElectronEnvironment = () => {
      try {
        const isElectron = typeof window !== 'undefined' && window.electronAPI;
        const hasAPI = isElectron && typeof window.electronAPI === 'object';
        
        let apiMethods: string[] = [];
        if (hasAPI) {
          apiMethods = Object.keys(window.electronAPI);
        }

        setElectronStatus({
          isElectron,
          hasAPI,
          apiMethods
        });

        console.log('Electron environment check:', {
          isElectron,
          hasAPI,
          apiMethods
        });
      } catch (error) {
        setElectronStatus({
          isElectron: false,
          hasAPI: false,
          apiMethods: [],
          error: error instanceof Error ? error.message : 'Unknown error'
        });
      }
    };

    checkElectronEnvironment();
  }, []);

  const testAPI = async () => {
    try {
      if (window.electronAPI && window.electronAPI.getDefaultConfig) {
        const config = await window.electronAPI.getDefaultConfig();
        console.log('API test successful:', config);
        alert('API test successful! Check console for details.');
      } else {
        alert('API not available');
      }
    } catch (error) {
      console.error('API test failed:', error);
      alert(`API test failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  return (
    <Paper sx={{ p: 3, m: 2 }}>
      <Typography variant="h6" gutterBottom>
        Electron Environment Test
      </Typography>
      
      <Box sx={{ mb: 2 }}>
        <Typography variant="body2">
          <strong>Is Electron:</strong> {electronStatus.isElectron ? '✅ Yes' : '❌ No'}
        </Typography>
        <Typography variant="body2">
          <strong>Has API:</strong> {electronStatus.hasAPI ? '✅ Yes' : '❌ No'}
        </Typography>
        <Typography variant="body2">
          <strong>API Methods:</strong> {electronStatus.apiMethods.length > 0 ? electronStatus.apiMethods.join(', ') : 'None'}
        </Typography>
      </Box>

      {electronStatus.error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          Error: {electronStatus.error}
        </Alert>
      )}

      {!electronStatus.isElectron && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          Running in browser mode. Some features will be limited.
        </Alert>
      )}

      {electronStatus.hasAPI && (
        <Button variant="contained" onClick={testAPI}>
          Test API
        </Button>
      )}
    </Paper>
  );
};
