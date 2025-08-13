import React, { useState } from 'react';
import {
  Box,
  Typography,
  Button,
  LinearProgress,
  Alert,
  Card,
  CardContent,
  Grid,
  Chip,
  Divider,
  FormControlLabel,
  Switch
} from '@mui/material';
import {
  PlayArrow,
  Stop,
  Refresh,
  CheckCircle,
  Error,
  Info
} from '@mui/icons-material';
import type { FileItem, ExifCraftConfig, ProcessingResult } from '../types';

interface ProcessingPanelProps {
  selectedFiles: FileItem[];
  config: ExifCraftConfig | null;
  processingStatus: ProcessingResult | null;
  onProcessImages: () => void;
}

export const ProcessingPanel: React.FC<ProcessingPanelProps> = ({
  selectedFiles,
  config,
  processingStatus,
  onProcessImages
}) => {
  const [dryRun, setDryRun] = useState(false);
  const [verbose, setVerbose] = useState(true);

  const selectedCount = selectedFiles.filter(f => f.selected).length;
  const isProcessing = processingStatus?.error === 'Processing...';
  const canProcess = selectedCount > 0 && config && !isProcessing;

  const getStatusIcon = () => {
    if (!processingStatus) return <Info />;
    if (processingStatus.success) return <CheckCircle color="success" />;
    if (processingStatus.error === 'Processing...') return <Refresh />;
    return <Error color="error" />;
  };

  const getStatusColor = () => {
    if (!processingStatus) return 'info';
    if (processingStatus.success) return 'success';
    if (processingStatus.error === 'Processing...') return 'info';
    return 'error';
  };

  const getStatusMessage = () => {
    if (!processingStatus) return 'Ready to process images';
    if (processingStatus.success) return 'Processing completed successfully!';
    if (processingStatus.error === 'Processing...') return 'Processing images...';
    return `Processing failed: ${processingStatus.error}`;
  };

  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        Processing
      </Typography>

      {/* Status Card */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
            {getStatusIcon()}
            <Typography variant="subtitle1">
              {getStatusMessage()}
            </Typography>
          </Box>

          {isProcessing && (
            <Box sx={{ width: '100%', mb: 2 }}>
              <LinearProgress />
            </Box>
          )}

          <Grid container spacing={2}>
            <Grid item xs={12} sm={6} md={3}>
              <Box>
                <Typography variant="body2" color="text.secondary">
                  Total Files
                </Typography>
                <Typography variant="h6">
                  {selectedFiles.length}
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Box>
                <Typography variant="body2" color="text.secondary">
                  Selected Files
                </Typography>
                <Typography variant="h6">
                  {selectedCount}
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Box>
                <Typography variant="body2" color="text.secondary">
                  Tasks Configured
                </Typography>
                <Typography variant="h6">
                  {config?.tasks.length || 0}
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Box>
                <Typography variant="body2" color="text.secondary">
                  AI Provider
                </Typography>
                <Chip 
                  label={config?.aiModel.provider || 'None'} 
                  size="small" 
                  color="primary"
                />
              </Box>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Processing Options */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="subtitle1" gutterBottom>
            Processing Options
          </Typography>
          
          <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
            <FormControlLabel
              control={
                <Switch
                  checked={dryRun}
                  onChange={(e) => setDryRun(e.target.checked)}
                  disabled={isProcessing}
                />
              }
              label="Dry Run (Simulate without modifying files)"
            />
            
            <FormControlLabel
              control={
                <Switch
                  checked={verbose}
                  onChange={(e) => setVerbose(e.target.checked)}
                  disabled={isProcessing}
                />
              }
              label="Verbose Output"
            />
          </Box>

          {dryRun && (
            <Alert severity="info" sx={{ mt: 2 }}>
              Dry run mode is enabled. Files will not be modified.
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Action Buttons */}
      <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
        <Button
          variant="contained"
          size="large"
          startIcon={<PlayArrow />}
          onClick={onProcessImages}
          disabled={!canProcess}
          sx={{ minWidth: 150 }}
        >
          {isProcessing ? 'Processing...' : 'Process Images'}
        </Button>

        <Button
          variant="outlined"
          size="large"
          startIcon={<Refresh />}
          onClick={() => window.location.reload()}
          disabled={isProcessing}
        >
          Reset
        </Button>
      </Box>

      {/* Validation Messages */}
      {selectedCount === 0 && (
        <Alert severity="warning" sx={{ mt: 2 }}>
          Please select at least one file to process.
        </Alert>
      )}

      {!config && (
        <Alert severity="warning" sx={{ mt: 2 }}>
          Please configure AI model and processing tasks.
        </Alert>
      )}

      {config && !config.aiModel.endpoint && (
        <Alert severity="error" sx={{ mt: 2 }}>
          AI model endpoint is required.
        </Alert>
      )}

      {config && config.tasks.length === 0 && (
        <Alert severity="error" sx={{ mt: 2 }}>
          At least one processing task is required.
        </Alert>
      )}

      {/* Processing Results */}
      {processingStatus && processingStatus.success && (
        <Alert severity="success" sx={{ mt: 2 }}>
          Image processing completed successfully! Check your files for updated EXIF metadata.
        </Alert>
      )}

      {processingStatus && !processingStatus.success && processingStatus.error !== 'Processing...' && (
        <Alert severity="error" sx={{ mt: 2 }}>
          Processing failed: {processingStatus.error}
        </Alert>
      )}
    </Box>
  );
};
