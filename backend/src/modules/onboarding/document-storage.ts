import { randomUUID } from 'node:crypto';
import { mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Errors } from '../../lib/errors.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Default private storage path inside project root
export const STORAGE_DIR = path.resolve(__dirname, '../../../storage/documents');

export const ALLOWED_MIME_TYPES = new Set([
  'application/pdf',
  'image/png',
  'image/jpeg',
]);

export const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024; // 10MB

export interface StoredFile {
  storageKey: string;
  fileName: string;
  fileSizeBytes: number;
  mimeType: string;
}

export class DocumentStorage {
  private initialized = false;

  constructor(private readonly baseDir: string = STORAGE_DIR) {}

  private async ensureDir(): Promise<void> {
    if (!this.initialized) {
      await mkdir(this.baseDir, { recursive: true });
      this.initialized = true;
    }
  }

  /**
   * Saves a file payload (Base64 string or Buffer) with validation.
   */
  async saveFile(params: {
    fileName: string;
    mimeType: string;
    content: Buffer | string; // raw Buffer or base64
  }): Promise<StoredFile> {
    const { fileName, mimeType, content } = params;

    if (!ALLOWED_MIME_TYPES.has(mimeType)) {
      throw Errors.validation({
        field: 'mime_type',
        allowed: Array.from(ALLOWED_MIME_TYPES),
        received: mimeType,
      }, `Unsupported file type: ${mimeType}. Allowed: PDF, PNG, JPEG.`);
    }

    const buffer = typeof content === 'string'
      ? Buffer.from(content, 'base64')
      : content;

    if (buffer.length === 0) {
      throw Errors.validation({ field: 'content' }, 'Uploaded file cannot be empty');
    }

    if (buffer.length > MAX_FILE_SIZE_BYTES) {
      throw Errors.validation({
        field: 'file_size',
        maxBytes: MAX_FILE_SIZE_BYTES,
        actualBytes: buffer.length,
      }, `File exceeds maximum allowed size of 10MB`);
    }

    await this.ensureDir();

    const sanitizedBase = path.basename(fileName).replace(/[^a-zA-Z0-9._-]/g, '_');
    const ext = path.extname(sanitizedBase) || (mimeType === 'application/pdf' ? '.pdf' : '.png');
    const storageKey = `doc_${randomUUID()}${ext}`;
    const destinationPath = path.join(this.baseDir, storageKey);

    await writeFile(destinationPath, buffer);

    return {
      storageKey,
      fileName: sanitizedBase,
      fileSizeBytes: buffer.length,
      mimeType,
    };
  }

  /**
   * Reads a file from storage.
   */
  async readFile(storageKey: string): Promise<Buffer> {
    await this.ensureDir();
    // Path traversal guard
    const normalized = path.basename(storageKey);
    const filePath = path.join(this.baseDir, normalized);

    try {
      return await readFile(filePath);
    } catch {
      throw Errors.notFound(`Document file not found`);
    }
  }

  /**
   * Removes a file if needed.
   */
  async deleteFile(storageKey: string): Promise<void> {
    const normalized = path.basename(storageKey);
    const filePath = path.join(this.baseDir, normalized);
    try {
      await unlink(filePath);
    } catch {
      // Ignored if already missing
    }
  }
}

export const documentStorage = new DocumentStorage();
