import React, { useState } from 'react';
import {
  Box,
  Typography,
  TextField,
  Button,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Switch,
  FormControlLabel,
  IconButton,
  Chip,
  Divider,
  Alert
} from '@mui/material';
import {
  ExpandMore,
  Add,
  Delete,
  Save,
  FolderOpen
} from '@mui/icons-material';
import type { ExifCraftConfig, TaskConfig, AIModelConfig, TagConfig } from '../types';

interface ConfigEditorProps {
  config: ExifCraftConfig | null;
  onConfigChange: (config: ExifCraftConfig) => void;
}

export const ConfigEditor: React.FC<ConfigEditorProps> = ({
  config,
  onConfigChange
}) => {
  const [error, setError] = useState<string | null>(null);

  if (!config) {
    return (
      <Box>
        <Typography variant="h6" gutterBottom>
          Configuration
        </Typography>
        <Alert severity="info">
          Loading configuration...
        </Alert>
      </Box>
    );
  }

  const handleAIModelChange = (field: keyof AIModelConfig, value: any) => {
    const updatedConfig = {
      ...config,
      aiModel: {
        ...config.aiModel,
        [field]: value
      }
    };
    onConfigChange(updatedConfig);
  };

  const handleTaskChange = (index: number, field: keyof TaskConfig, value: any) => {
    const updatedTasks = [...config.tasks];
    updatedTasks[index] = {
      ...updatedTasks[index],
      [field]: value
    };

    const updatedConfig = {
      ...config,
      tasks: updatedTasks
    };
    onConfigChange(updatedConfig);
  };

  const handleTagChange = (taskIndex: number, tagIndex: number, field: keyof TagConfig, value: any) => {
    const updatedTasks = [...config.tasks];
    const updatedTags = [...updatedTasks[taskIndex].tags];
    updatedTags[tagIndex] = {
      ...updatedTags[tagIndex],
      [field]: value
    };
    updatedTasks[taskIndex] = {
      ...updatedTasks[taskIndex],
      tags: updatedTags
    };

    const updatedConfig = {
      ...config,
      tasks: updatedTasks
    };
    onConfigChange(updatedConfig);
  };

  const handleAddTask = () => {
    const newTask: TaskConfig = {
      name: `Task ${config.tasks.length + 1}`,
      prompt: 'Describe this image',
      tags: [
        {
          name: 'ImageDescription',
          allowOverwrite: true
        }
      ]
    };

    const updatedConfig = {
      ...config,
      tasks: [...config.tasks, newTask]
    };
    onConfigChange(updatedConfig);
  };

  const handleRemoveTask = (index: number) => {
    const updatedTasks = config.tasks.filter((_, i) => i !== index);
    const updatedConfig = {
      ...config,
      tasks: updatedTasks
    };
    onConfigChange(updatedConfig);
  };

  const handleAddTag = (taskIndex: number) => {
    const updatedTasks = [...config.tasks];
    const newTag: TagConfig = {
      name: 'ImageTitle',
      allowOverwrite: true
    };
    updatedTasks[taskIndex] = {
      ...updatedTasks[taskIndex],
      tags: [...updatedTasks[taskIndex].tags, newTag]
    };

    const updatedConfig = {
      ...config,
      tasks: updatedTasks
    };
    onConfigChange(updatedConfig);
  };

  const handleRemoveTag = (taskIndex: number, tagIndex: number) => {
    const updatedTasks = [...config.tasks];
    const updatedTags = updatedTasks[taskIndex].tags.filter((_, i) => i !== tagIndex);
    updatedTasks[taskIndex] = {
      ...updatedTasks[taskIndex],
      tags: updatedTags
    };

    const updatedConfig = {
      ...config,
      tasks: updatedTasks
    };
    onConfigChange(updatedConfig);
  };

  const handleSaveConfig = async () => {
    try {
      setError(null);
      
      if (typeof window !== 'undefined' && window.electronAPI) {
        const savedPath = await window.electronAPI.saveConfig(config);
        if (savedPath) {
          // Show success message
          console.log('Configuration saved to:', savedPath);
        }
      } else {
        setError('Save configuration requires Electron environment');
      }
    } catch (error) {
      setError('Failed to save configuration');
      console.error('Error saving config:', error);
    }
  };

  const handleLoadConfig = async () => {
    try {
      setError(null);
      
      if (typeof window !== 'undefined' && window.electronAPI) {
        const loadedConfig = await window.electronAPI.loadConfig();
        if (loadedConfig) {
          onConfigChange(loadedConfig);
        }
      } else {
        setError('Load configuration requires Electron environment');
      }
    } catch (error) {
      setError('Failed to load configuration');
      console.error('Error loading config:', error);
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Typography variant="h6">
          Configuration
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="outlined"
            size="small"
            startIcon={<FolderOpen />}
            onClick={handleLoadConfig}
          >
            Load
          </Button>
          <Button
            variant="outlined"
            size="small"
            startIcon={<Save />}
            onClick={handleSaveConfig}
          >
            Save
          </Button>
        </Box>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* AI Model Configuration */}
      <Accordion defaultExpanded>
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Typography variant="subtitle1">AI Model Settings</Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <FormControl fullWidth>
              <InputLabel>Provider</InputLabel>
              <Select
                value={config.aiModel.provider}
                label="Provider"
                onChange={(e) => handleAIModelChange('provider', e.target.value)}
              >
                <MenuItem value="ollama">Ollama</MenuItem>
                <MenuItem value="openai">OpenAI</MenuItem>
                <MenuItem value="gemini">Gemini</MenuItem>
              </Select>
            </FormControl>

            <TextField
              fullWidth
              label="Endpoint"
              value={config.aiModel.endpoint}
              onChange={(e) => handleAIModelChange('endpoint', e.target.value)}
            />

            <TextField
              fullWidth
              label="Model"
              value={config.aiModel.model}
              onChange={(e) => handleAIModelChange('model', e.target.value)}
            />

            {config.aiModel.provider !== 'ollama' && (
              <TextField
                fullWidth
                label="API Key"
                type="password"
                value={config.aiModel.key || ''}
                onChange={(e) => handleAIModelChange('key', e.target.value)}
              />
            )}

            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                label="Temperature"
                type="number"
                value={config.aiModel.options?.temperature || 0}
                onChange={(e) => handleAIModelChange('options', {
                  ...config.aiModel.options,
                  temperature: parseFloat(e.target.value)
                })}
                inputProps={{ min: 0, max: 2, step: 0.1 }}
              />
              <TextField
                label="Max Tokens"
                type="number"
                value={config.aiModel.options?.max_tokens || 500}
                onChange={(e) => handleAIModelChange('options', {
                  ...config.aiModel.options,
                  max_tokens: parseInt(e.target.value)
                })}
                inputProps={{ min: 1, max: 4000 }}
              />
            </Box>
          </Box>
        </AccordionDetails>
      </Accordion>

      {/* Tasks Configuration */}
      <Accordion defaultExpanded>
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
            <Typography variant="subtitle1">Processing Tasks</Typography>
            <Button
              variant="outlined"
              size="small"
              startIcon={<Add />}
              onClick={handleAddTask}
            >
              Add Task
            </Button>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {config.tasks.map((task, taskIndex) => (
              <Box key={taskIndex} sx={{ border: 1, borderColor: 'grey.300', borderRadius: 1, p: 2 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                  <Typography variant="subtitle2">Task {taskIndex + 1}</Typography>
                  <IconButton
                    size="small"
                    onClick={() => handleRemoveTask(taskIndex)}
                    color="error"
                  >
                    <Delete />
                  </IconButton>
                </Box>

                <TextField
                  fullWidth
                  label="Task Name"
                  value={task.name}
                  onChange={(e) => handleTaskChange(taskIndex, 'name', e.target.value)}
                  sx={{ mb: 2 }}
                />

                <TextField
                  fullWidth
                  label="Prompt"
                  multiline
                  rows={3}
                  value={task.prompt}
                  onChange={(e) => handleTaskChange(taskIndex, 'prompt', e.target.value)}
                  sx={{ mb: 2 }}
                />

                <Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                    <Typography variant="body2">EXIF Tags</Typography>
                    <Button
                      variant="text"
                      size="small"
                      startIcon={<Add />}
                      onClick={() => handleAddTag(taskIndex)}
                    >
                      Add Tag
                    </Button>
                  </Box>

                  {task.tags.map((tag, tagIndex) => (
                    <Box key={tagIndex} sx={{ display: 'flex', gap: 1, mb: 1, alignItems: 'center' }}>
                      <TextField
                        label="Tag Name"
                        value={tag.name}
                        onChange={(e) => handleTagChange(taskIndex, tagIndex, 'name', e.target.value)}
                        size="small"
                        sx={{ flexGrow: 1 }}
                      />
                      <FormControlLabel
                        control={
                          <Switch
                            checked={tag.allowOverwrite}
                            onChange={(e) => handleTagChange(taskIndex, tagIndex, 'allowOverwrite', e.target.checked)}
                            size="small"
                          />
                        }
                        label="Overwrite"
                      />
                      <IconButton
                        size="small"
                        onClick={() => handleRemoveTag(taskIndex, tagIndex)}
                        color="error"
                      >
                        <Delete />
                      </IconButton>
                    </Box>
                  ))}
                </Box>
              </Box>
            ))}
          </Box>
        </AccordionDetails>
      </Accordion>

      {/* General Settings */}
      <Accordion>
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Typography variant="subtitle1">General Settings</Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <TextField
              fullWidth
              label="Base Prompt"
              multiline
              rows={2}
              value={config.basePrompt || ''}
              onChange={(e) => onConfigChange({ ...config, basePrompt: e.target.value })}
            />

            <FormControlLabel
              control={
                <Switch
                  checked={config.preserveOriginal}
                  onChange={(e) => onConfigChange({ ...config, preserveOriginal: e.target.checked })}
                />
              }
              label="Preserve Original Files"
            />

            <Box>
              <Typography variant="body2" gutterBottom>
                Supported Image Formats
              </Typography>
              <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                {config.imageFormats.map((format, index) => (
                  <Chip key={index} label={format} size="small" />
                ))}
              </Box>
            </Box>
          </Box>
        </AccordionDetails>
      </Accordion>
    </Box>
  );
};
