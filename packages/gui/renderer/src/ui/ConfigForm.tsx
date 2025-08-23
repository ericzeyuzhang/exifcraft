import React, { useEffect } from 'react';
import { useFieldArray, useForm, useWatch } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { ExifCraftConfigSchema } from 'exifcraft-core/schema';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { Textarea } from '../components/ui/Textarea';
import { TriStateCheckbox } from '../components/ui/TriStateCheckbox';

type FormSchema = z.infer<typeof ExifCraftConfigSchema>;

export interface ConfigFormProps {
  value?: FormSchema | null;
  onChange?: (val: FormSchema) => void;
}

export const ConfigForm: React.FC<ConfigFormProps> = ({ value, onChange }) => {
  const defaultValues: FormSchema = value || {
    tasks: [
      {
        name: 'Title',
        prompt: 'Generate a concise title for this photo.',
        tags: [{ name: 'Title', avoidOverwrite: true }]
      }
    ],
    aiModel: {
      provider: 'mock',
      endpoint: 'http://localhost:11434',
      model: 'llama3'
    },
    imageFormats: ['jpg', 'jpeg', 'heic', 'heif', 'png', 'webp'],
    preserveOriginal: true,
    basePrompt: ''
  };

  const { register, handleSubmit, reset, control, setValue, trigger, getValues, formState: { errors } } = useForm<FormSchema>({
    resolver: zodResolver(ExifCraftConfigSchema),
    defaultValues
  });

  const { fields, append, remove } = useFieldArray({ control, name: 'tasks' });

  const imageFormats = useWatch({ control, name: 'imageFormats' }) as string[] | undefined;
  const imageFormatSet = new Set(imageFormats || []);

  const groupStandard = ['jpg','jpeg','heic','heif','png','webp'];
  const groupRaw = ['dng','arw','nef','cr2','cr3','raw','raf'];
  const groupTiff = ['tif','tiff'];

  function toggleFormat(ext: string, checked: boolean) {
    console.log('toggleFormat called:', ext, checked);
    const next = new Set(imageFormatSet);
    if (checked) next.add(ext); else next.delete(ext);
    const ordered = Array.from(next);
    console.log('Setting imageFormats to:', ordered);
    setValue('imageFormats', ordered);
    
    // Trigger form change notification
    setTimeout(() => {
      const currentValues = getValues();
      console.log('Current form values:', currentValues);
      onChange?.(currentValues);
    }, 0);
  }

  function getGroupState(group: string[]) {
    const selectedCount = group.filter(ext => imageFormatSet.has(ext)).length;
    if (selectedCount === 0) return false;
    if (selectedCount === group.length) return true;
    return null; // partial selection
  }

  function setGroup(group: string[], state: boolean | null) {
    const next = new Set(imageFormatSet);
    if (state === true) {
      // Select all
      group.forEach(g => next.add(g));
    } else if (state === false) {
      // Deselect all
      group.forEach(g => next.delete(g));
    } else {
      // null state - toggle to opposite of current majority
      const selectedCount = group.filter(ext => imageFormatSet.has(ext)).length;
      const shouldSelectAll = selectedCount < group.length / 2;
      group.forEach(g => {
        if (shouldSelectAll) next.add(g);
        else next.delete(g);
      });
    }
    const ordered = Array.from(next);
    setValue('imageFormats', ordered);
    
    // Trigger form change notification
    setTimeout(() => {
      const currentValues = getValues();
      console.log('Group change - Current form values:', currentValues);
      onChange?.(currentValues);
    }, 0);
  }

  function handleGroupToggle(group: string[]) {
    const currentState = getGroupState(group);
    console.log('handleGroupToggle called:', group, 'currentState:', currentState);
    let nextState: boolean | null;
    
    if (currentState === false) {
      nextState = true; // none -> all
    } else if (currentState === true) {
      nextState = false; // all -> none
    } else {
      nextState = true; // partial -> all
    }
    
    console.log('nextState:', nextState);
    setGroup(group, nextState);
  }

  useEffect(() => {
    if (value && JSON.stringify(value) !== JSON.stringify(defaultValues)) {
      reset(value);
    }
  }, [value, reset]);

  const onSubmit = (data: FormSchema) => {
    onChange?.(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} style={{ display: 'grid', gap: 8, maxWidth: 800 }}>
      <fieldset style={{ border: '1px solid #eee', padding: 12 }}>
        <legend>AI Model</legend>
        <div>
          <label>Provider:&nbsp;</label>
          <select {...register('aiModel.provider')}>
            <option value="ollama">ollama</option>
            <option value="openai">openai</option>
            <option value="gemini">gemini</option>
            <option value="mock">mock</option>
          </select>
        </div>
        <div className="flex items-center gap-2">
          <label className="w-24">Endpoint:</label>
          <Input {...register('aiModel.endpoint')} placeholder="http://localhost:11434" className="w-[400px]" />
          {errors.aiModel?.endpoint && <span style={{ color: 'red', marginLeft: 8 }}>{errors.aiModel.endpoint.message as string}</span>}
        </div>
        <div>
          <label className="w-24">Model:</label>
          <Input {...register('aiModel.model')} placeholder="llama3" />
          {errors.aiModel?.model && <span style={{ color: 'red', marginLeft: 8 }}>{errors.aiModel.model.message as string}</span>}
        </div>
      </fieldset>

      <fieldset style={{ border: '1px solid #eee', padding: 12 }}>
        <legend>Image Formats</legend>
        <div className="bg-gray-50 p-3 rounded-md">
          <div className="mb-2">
            <TriStateCheckbox
              checked={getGroupState(groupStandard)}
              onChange={() => handleGroupToggle(groupStandard)}
              label="Standard:"
            />
          </div>
          <div className="flex gap-4 flex-wrap ml-6">
            {groupStandard.map((ext) => (
              <label key={ext} className="flex items-center gap-2 text-sm">
                <input 
                  type="checkbox" 
                  checked={imageFormatSet.has(ext)} 
                  onChange={(e) => toggleFormat(ext, e.target.checked)}
                  className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                />
                {ext}
              </label>
            ))}
          </div>
        </div>
        <div className="bg-gray-50 p-3 rounded-md mt-3">
          <div className="mb-2">
            <TriStateCheckbox
              checked={getGroupState(groupRaw)}
              onChange={() => handleGroupToggle(groupRaw)}
              label="Raw:"
            />
          </div>
          <div className="flex gap-4 flex-wrap ml-6">
            {groupRaw.map((ext) => (
              <label key={ext} className="flex items-center gap-2 text-sm">
                <input 
                  type="checkbox" 
                  checked={imageFormatSet.has(ext)} 
                  onChange={(e) => toggleFormat(ext, e.target.checked)}
                  className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                />
                {ext}
              </label>
            ))}
          </div>
        </div>
        <div className="bg-gray-50 p-3 rounded-md mt-3">
          <div className="mb-2">
            <TriStateCheckbox
              checked={getGroupState(groupTiff)}
              onChange={() => handleGroupToggle(groupTiff)}
              label="Tiff:"
            />
          </div>
          <div className="flex gap-4 flex-wrap ml-6">
            {groupTiff.map((ext) => (
              <label key={ext} className="flex items-center gap-2 text-sm">
                <input 
                  type="checkbox" 
                  checked={imageFormatSet.has(ext)} 
                  onChange={(e) => toggleFormat(ext, e.target.checked)}
                  className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                />
                {ext}
              </label>
            ))}
          </div>
        </div>
      </fieldset>

      <fieldset style={{ border: '1px solid #eee', padding: 12 }}>
        <legend>General</legend>
        <div>
          <label>Preserve Original:&nbsp;</label>
          <input type="checkbox" {...register('preserveOriginal')} />
        </div>
        <div>
          <label className="w-24">Base Prompt:</label>
          <Textarea {...register('basePrompt')} placeholder="Global instruction to prepend to prompts" className="w-[400px]" />
        </div>
      </fieldset>

      <div className="space-y-3">
        {fields.map((field, idx) => (
          <fieldset key={field.id} style={{ border: '1px solid #eee', padding: 12 }}>
            <legend>Task[{idx}]</legend>
            <div className="flex items-center gap-2">
              <label className="w-24">Name:</label>
              <Input {...register(`tasks.${idx}.name` as const)} placeholder="Title" />
              {errors.tasks?.[idx]?.name && <span style={{ color: 'red', marginLeft: 8 }}>{errors.tasks?.[idx]?.name?.message as string}</span>}
            </div>
            <div className="flex items-center gap-2">
              <label className="w-24">Prompt:</label>
              <Input {...register(`tasks.${idx}.prompt` as const)} placeholder="Generate a concise title for this photo." className="w-[500px]" />
              {errors.tasks?.[idx]?.prompt && <span style={{ color: 'red', marginLeft: 8 }}>{errors.tasks?.[idx]?.prompt?.message as string}</span>}
            </div>
            <div className="flex items-center gap-2">
              <label className="w-24">Tag Name:</label>
              <Input {...register(`tasks.${idx}.tags.0.name` as const)} placeholder="Title" />
              {errors.tasks?.[idx]?.tags?.[0]?.name && <span style={{ color: 'red', marginLeft: 8 }}>{errors.tasks?.[idx]?.tags?.[0]?.name?.message as string}</span>}
            </div>
            <div>
              <label>Avoid Overwrite:&nbsp;</label>
              <input type="checkbox" {...register(`tasks.${idx}.tags.0.avoidOverwrite` as const)} />
            </div>
            <div>
              <Button type="button" variant="secondary" size="sm" onClick={() => remove(idx)}>Delete Task</Button>
            </div>
          </fieldset>
        ))}
        <Button type="button" size="sm" onClick={() => append({ name: 'New Task', prompt: '', tags: [{ name: 'Title', avoidOverwrite: true }] })}>Add Task</Button>
      </div>

      <div>
        <button type="submit">Apply</button>
      </div>
    </form>
  );
};


