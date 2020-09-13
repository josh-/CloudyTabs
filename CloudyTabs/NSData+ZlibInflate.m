//
//  NSData+ZlibInflate.m
//  CloudyTabs
//
//  Based off NSData+Compression from CocoaGit
//  https://github.com/geoffgarside/cocoagit/blob/master/Source/Categories/NSData+Compression.m
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "NSData+ZlibInflate.h"
#include <zlib.h>

@implementation NSData (ZlibInflate)

- (NSData *)ZlibInflate {
    NSUInteger length = self.length;
    
    if (length == 0) {
        return self;
    }
    
    NSUInteger halfLength = length / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength:length + halfLength];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)self.bytes;
    strm.avail_in = (int)length;
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit (&strm) != Z_OK) {
        return nil;
    }
    
    while (!done) {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= decompressed.length) {
            [decompressed increaseLengthBy: halfLength];
        }
        strm.next_out = decompressed.mutableBytes + strm.total_out;
        strm.avail_out = (int)decompressed.length - (int)strm.total_out;
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) {
            done = YES;
        } else if (status != Z_OK) {
            break;
        }
    }
    if (inflateEnd (&strm) != Z_OK) {
        return nil;
    }
    
    // Set real length.
    if (done) {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    } else {
        return nil;
    }
}

@end
