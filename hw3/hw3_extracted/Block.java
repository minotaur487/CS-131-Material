import java.util.zip.*;
import java.util.concurrent.ConcurrentHashMap;

class Block implements Runnable {
    private final static int DICT_SIZE = 32768;
    public final static int BLOCK_SIZE = 131072;
    private byte[] data;
    public int sizeOfData;
    public boolean isFirstBlock;
    public boolean isLastBlock;
    private int position;
    private static ConcurrentHashMap<Integer, Pair> compressedBlocks;
    private static ConcurrentHashMap<Integer, byte[]> dictOfBlocks;
    private static ConcurrentHashMap<Integer, Pair> uncompressedBlocks;

    public Block(byte[] blockOfBytes,
                 int size,
                 boolean isFirstBlock,
                 boolean isLastBlock,
                 int pos,
                 ConcurrentHashMap<Integer, Pair> compressedBlocks,
                 ConcurrentHashMap<Integer, byte[]> dictOfBlocks,
                 ConcurrentHashMap<Integer, Pair> uncompressedBlocks) {
        this.data = blockOfBytes;
        this.sizeOfData = size;
        this.isFirstBlock = isFirstBlock;
        this.isLastBlock = isLastBlock;
        this.position = pos;
        this.compressedBlocks = compressedBlocks;
        this.dictOfBlocks = dictOfBlocks;
        this.uncompressedBlocks = uncompressedBlocks;
    }

    public void run() {
        Deflater compressor = new Deflater(Deflater.DEFAULT_COMPRESSION, true);
        // byte[] blockBuf = data;
        byte[] blockBuf = uncompressedBlocks.get(position).a;
        compressor.reset();
        /* If we saved a dictionary from the last block, prime the deflater with
        * it */
        if (!isFirstBlock) {
            byte[] curDict = dictOfBlocks.get(position-1);
            if (curDict != null)
                compressor.setDictionary(curDict);
        }

        compressor.setInput(blockBuf, 0, sizeOfData);

        byte[] cmpBlockBuf = new byte[BLOCK_SIZE * 2];
        compressor.finish();
        while (!compressor.finished()) {
            int deflatedBytes = compressor.deflate(
                cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.SYNC_FLUSH);
            if (deflatedBytes > 0) {
                Pair val = new Pair(cmpBlockBuf, deflatedBytes);
                compressedBlocks.put(position, val);
            }
        }
        /* If we read in enough bytes in this block, store the last part as the
        diction ary for the next iteration */
        if (sizeOfData >= DICT_SIZE) {
            byte[] dictBuf = new byte[DICT_SIZE];
            System.arraycopy(blockBuf, sizeOfData - DICT_SIZE, dictBuf, 0, DICT_SIZE);
            dictOfBlocks.put(position, dictBuf);
        }   // Default is false
    }
}
