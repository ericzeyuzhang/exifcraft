import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Checkbox,
  IconButton,
  Chip,
  Divider,
  Alert
} from '@mui/material';
import {
  FolderOpen,
  Image,
  Delete,
  Add,
  Folder
} from '@mui/icons-material';
import type { FileItem } from '../types';

interface FileSelectorProps {
  selectedFiles: FileItem[];
  onFilesSelected: (files: FileItem[]) => void;
}

export const FileSelector: React.FC<FileSelectorProps> = ({
  selectedFiles,
  onFilesSelected
}) => {
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Set up menu event listeners only in Electron environment
    if (typeof window !== 'undefined' && window.electronAPI) {
      const handleMenuOpenImages = () => handleSelectFiles();
      const handleMenuOpenDirectory = () => handleSelectDirectory();

      window.electronAPI.onMenuOpenImages(handleMenuOpenImages);
      window.electronAPI.onMenuOpenDirectory(handleMenuOpenDirectory);

      return () => {
        window.electronAPI.removeAllListeners('menu-open-images');
        window.electronAPI.removeAllListeners('menu-open-directory');
      };
    }
  }, []);

  const handleSelectFiles = async () => {
    try {
      setError(null);
      
      if (typeof window !== 'undefined' && window.electronAPI) {
        const filePaths = await window.electronAPI.selectFiles();
        
        if (filePaths && filePaths.length > 0) {
          const newFiles: FileItem[] = filePaths.map((path: string) => ({
            path,
            name: path.split('/').pop() || path.split('\\').pop() || path,
            size: 0, // Will be updated if needed
            type: path.split('.').pop()?.toLowerCase() || '',
            selected: true
          }));

          // Merge with existing files, avoiding duplicates
          const existingPaths = new Set(selectedFiles.map(f => f.path));
          const uniqueNewFiles = newFiles.filter(f => !existingPaths.has(f.path));
          
          onFilesSelected([...selectedFiles, ...uniqueNewFiles]);
        }
      } else {
        setError('File selection requires Electron environment');
      }
    } catch (error) {
      setError('Failed to select files');
      console.error('Error selecting files:', error);
    }
  };

  const handleSelectDirectory = async () => {
    try {
      setError(null);
      
      if (typeof window !== 'undefined' && window.electronAPI) {
        const directoryPath = await window.electronAPI.selectDirectory();
        
        if (directoryPath) {
          // For now, we'll just add the directory as a placeholder
          // In a full implementation, you'd scan the directory for image files
          const newFile: FileItem = {
            path: directoryPath,
            name: directoryPath.split('/').pop() || directoryPath.split('\\').pop() || directoryPath,
            size: 0,
            type: 'directory',
            selected: true
          };

          const existingPaths = new Set(selectedFiles.map(f => f.path));
          if (!existingPaths.has(directoryPath)) {
            onFilesSelected([...selectedFiles, newFile]);
          }
        }
      } else {
        setError('Directory selection requires Electron environment');
      }
    } catch (error) {
      setError('Failed to select directory');
      console.error('Error selecting directory:', error);
    }
  };

  const handleFileToggle = (filePath: string) => {
    const updatedFiles = selectedFiles.map(file =>
      file.path === filePath ? { ...file, selected: !file.selected } : file
    );
    onFilesSelected(updatedFiles);
  };

  const handleRemoveFile = (filePath: string) => {
    const updatedFiles = selectedFiles.filter(file => file.path !== filePath);
    onFilesSelected(updatedFiles);
  };

  const handleSelectAll = () => {
    const updatedFiles = selectedFiles.map(file => ({ ...file, selected: true }));
    onFilesSelected(updatedFiles);
  };

  const handleDeselectAll = () => {
    const updatedFiles = selectedFiles.map(file => ({ ...file, selected: false }));
    onFilesSelected(updatedFiles);
  };

  const selectedCount = selectedFiles.filter(f => f.selected).length;

  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        File Selection
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Box sx={{ mb: 2, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
        <Button
          variant="outlined"
          startIcon={<Add />}
          onClick={handleSelectFiles}
        >
          Select Files
        </Button>
        <Button
          variant="outlined"
          startIcon={<Folder />}
          onClick={handleSelectDirectory}
        >
          Select Directory
        </Button>
        {selectedFiles.length > 0 && (
          <>
            <Button
              variant="text"
              size="small"
              onClick={handleSelectAll}
            >
              Select All
            </Button>
            <Button
              variant="text"
              size="small"
              onClick={handleDeselectAll}
            >
              Deselect All
            </Button>
          </>
        )}
      </Box>

      {selectedFiles.length > 0 && (
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
            <Typography variant="body2" color="text.secondary">
              {selectedCount} of {selectedFiles.length} files selected
            </Typography>
          </Box>

          <List dense sx={{ maxHeight: 300, overflow: 'auto' }}>
            {selectedFiles.map((file, index) => (
              <React.Fragment key={file.path}>
                <ListItem>
                  <Checkbox
                    checked={file.selected}
                    onChange={() => handleFileToggle(file.path)}
                    size="small"
                  />
                  <ListItemText
                    primary={file.name}
                    secondary={file.path}
                    primaryTypographyProps={{ variant: 'body2' }}
                    secondaryTypographyProps={{ variant: 'caption' }}
                  />
                  <ListItemSecondaryAction>
                    <IconButton
                      edge="end"
                      size="small"
                      onClick={() => handleRemoveFile(file.path)}
                    >
                      <Delete />
                    </IconButton>
                  </ListItemSecondaryAction>
                </ListItem>
                {index < selectedFiles.length - 1 && <Divider />}
              </React.Fragment>
            ))}
          </List>
        </Box>
      )}

      {selectedFiles.length === 0 && (
        <Box
          sx={{
            border: '2px dashed',
            borderColor: 'grey.300',
            borderRadius: 2,
            p: 4,
            textAlign: 'center'
          }}
        >
          <Image sx={{ fontSize: 48, color: 'grey.400', mb: 2 }} />
          <Typography variant="body2" color="text.secondary">
            No files selected. Click "Select Files" or "Select Directory" to get started.
          </Typography>
        </Box>
      )}
    </Box>
  );
};
