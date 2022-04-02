import java.io.*;
import java.util.zip.*;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.RejectedExecutionException;

class MultiThreadedGZipCompressor {
    public final static int BLOCK_SIZE = 131072;
    private final static int GZIP_MAGIC = 0x8b1f;
    private final static int TRAILER_SIZE = 8;
    private static LinkedBlockingQueue<Runnable> blocksQueued;
    private LinkedBlockingQueue<Runnable> totalBlocks;
    private static int numOfThreads;
    public ByteArrayOutputStream outStream;
    private CRC32 crc = new CRC32();
    private ConcurrentHashMap<Integer, Pair> compressedBlocks;
    private ConcurrentHashMap<Integer, Pair> uncompressedBlocks;
    private static ConcurrentHashMap<Integer, byte[]> dictOfBlocks;
    private BlockNumberTracker bnt;
    private long totalDataLength = 0;
    private ThreadPoolExecutor threadPool;

    public MultiThreadedGZipCompressor(int numOfThreads) {
        this.outStream = new ByteArrayOutputStream();
        this.blocksQueued = new LinkedBlockingQueue<Runnable>();
        this.totalBlocks = new LinkedBlockingQueue<Runnable>();
        this.numOfThreads = numOfThreads;
        this.compressedBlocks = new ConcurrentHashMap<Integer, Pair>();
        this.dictOfBlocks = new ConcurrentHashMap<Integer, byte[]>();
        this.uncompressedBlocks = new ConcurrentHashMap<Integer, Pair>();
        this.bnt = new BlockNumberTracker(numOfThreads - 1);
    }

    private void writeHeader() throws IOException {
    outStream.write(new byte[] {
        (byte)GZIP_MAGIC,        // Magic number (short)
        (byte)(GZIP_MAGIC >> 8), // Magic number (short)
        Deflater.DEFLATED,       // Compression method (CM)
        0,                       // Flags (FLG)
        0,                       // Modification time MTIME (int)
        0,                       // Modification time MTIME (int)
        0,                       // Modification time MTIME (int)
        0,                       // Modification time MTIME (int)Sfil
        0,                       // Extra flags (XFLG)
        0                        // Operating system (OS)
    });
    }
    /*
    * Writes GZIP member trailer to a byte array, starting at a given
    * offset.
    */
    private void writeTrailer(long totalBytes, byte[] buf, int offset)
        throws IOException {
        writeInt((int)crc.getValue(), buf, offset); // CRC-32 of uncompr. data
        writeInt((int)totalBytes, buf, offset + 4); // Number of uncompr. bytes
    }
    /*
    * Writes integer in Intel byte order to a byte array, starting at a
    * given offset.
    */
    private void writeInt(int i, byte[] buf, int offset) throws IOException {
        writeShort(i & 0xffff, buf, offset);
        writeShort((i >> 16) & 0xffff, buf, offset + 2);
    }
    /*
    * Writes short integer in Intel byte order to a byte array, starting
    * at a given offset
    */
    private void writeShort(int s, byte[] buf, int offset) throws IOException {
        buf[offset] = (byte)(s & 0xff);
        buf[offset + 1] = (byte)((s >> 8) & 0xff);
    }

    public void compress() throws IOException {    
        InputStream inStream = new BufferedInputStream(System.in);


        threadPool = new ThreadPoolExecutor(numOfThreads,    // core pool size and max pool size are the same->fixes thread pool size
                                            numOfThreads,
                                            1,
                                            TimeUnit.NANOSECONDS,
                                            blocksQueued);    // Where the tasks to process the blocks reside
        try {
            initializeThreads(inStream);
            int numOfBlocks = totalBlocks.size();

            int i = 0;
            while (i < numOfBlocks) {
                threadPool.execute(totalBlocks.take());
                i++;
            }

            outStream.reset();
            writeHeader();

            int k = 0;
            while ((k < numOfBlocks) && !bnt.gotLastBlock()) {
                if (compressedBlocks.containsKey(k)) {
                    Pair cur = compressedBlocks.get(k);
                    outStream.write(cur.a, 0, cur.b);
                    k++;
                }
            }
            threadPool.shutdown();

            /* Finally, write the trailer and then write to STDOUT */
            byte[] trailerBuf = new byte[TRAILER_SIZE];
            // writeTrailer(totalInput.length, trailerBuf, 0);
            writeTrailer(totalDataLength, trailerBuf, 0);
            outStream.write(trailerBuf);
            outStream.writeTo(System.out);
        } catch (Throwable e) {
            threadPool.shutdownNow();
            System.err.println(e.toString());
            System.exit(-1);        
        }
    }

    private synchronized void initializeThreads(InputStream inStream) {
        boolean isFirst = true;
        boolean isLast = false;
        int nBytesNext;
        byte[] blockBuf = new byte[BLOCK_SIZE];
        int pos = 0;
        this.crc.reset();
        try {
            int nBytes = inStream.read(blockBuf);
            while (nBytes > 0) {                
                // keep track of all input bytes for checksum
                totalDataLength += nBytes;
                crc.update(blockBuf, 0, nBytes);
                outStream.write(blockBuf, 0, nBytes);
                
                nBytesNext = inStream.read(blockBuf);
                if (nBytesNext <= 0)
                    isLast = true;
                
                byte[] data = new byte[BLOCK_SIZE];
                System.arraycopy(blockBuf, 0, data, 0, nBytes);

                uncompressedBlocks.put(pos, new Pair(data, nBytes));
                totalBlocks.put(new Block(data, nBytes, isFirst, isLast,
                pos, compressedBlocks, dictOfBlocks, uncompressedBlocks));

                pos++;
                isFirst = false;
                nBytes = nBytesNext;
            }
        } catch (Throwable e) {
            System.err.println("Write/Read Error");
            System.exit(-1);
        }
    }
}
