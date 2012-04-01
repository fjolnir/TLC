-- CoreFoundation essentials, feel free to add missing bits if you find you need them

local ffi = require("ffi")

ffi.cdef([[
typedef unsigned char           Boolean;
typedef unsigned char           UInt8;
typedef signed char             SInt8;
typedef unsigned short          UInt16;
typedef signed short            SInt16;
typedef unsigned int            UInt32;
typedef signed int              SInt32;
typedef uint64_t                UInt64;
typedef int64_t                 SInt64;
typedef SInt32                  OSStatus;
typedef float                   Float32;
typedef double                  Float64;
typedef unsigned short          UniChar;
typedef unsigned long           UniCharCount;
typedef unsigned char *         StringPtr;
typedef const unsigned char *   ConstStringPtr;
typedef unsigned char           Str255[256];
typedef const unsigned char *   ConstStr255Param;
typedef SInt16                  OSErr;
typedef SInt16                  RegionCode;
typedef SInt16                  LangCode;
typedef SInt16                  ScriptCode;
typedef UInt32                  FourCharCode;
typedef FourCharCode            OSType;
typedef UInt8                   Byte;
typedef SInt8                   SignedByte;
typedef UInt32                  UTF32Char;
typedef UInt16                  UTF16Char;
typedef UInt8                   UTF8Char;

typedef unsigned long CFTypeID;
typedef unsigned long CFOptionFlags;
typedef unsigned long CFHashCode;
typedef signed long CFIndex;

/* Base "type" of all "CF objects", and polymorphic functions on them */
typedef const void * CFTypeRef;


//typedef const struct __CFString * CFStringRef;
//typedef struct __CFString * CFMutableStringRef;
typedef const CFTypeRef CFStringRef;
typedef CFTypeRef CFMutableStringRef;
/*
        Type to mean any instance of a property list type;
        currently, CFString, CFData, CFNumber, CFBoolean, CFDate,
        CFArray, and CFDictionary.
*/
typedef CFTypeRef CFPropertyListRef;

/* Values returned from comparison functions */
enum {
    kCFCompareLessThan = -1,
    kCFCompareEqualTo = 0,
    kCFCompareGreaterThan = 1
};
typedef CFIndex CFComparisonResult;

/* A standard comparison function */
typedef CFComparisonResult (*CFComparatorFunction)(const void *val1, const void *val2, void *context);

/* Constant used by some functions to indicate failed searches. */
/* This is of type CFIndex. */
enum {
    kCFNotFound = -1
};

/* Range type */
typedef struct {
    CFIndex location;
    CFIndex length;
} CFRange;

//typedef const struct __CFAllocator * CFAllocatorRef;
typedef const CFTypeRef CFAllocatorRef;

/* This is a synonym for NULL, if you'd rather use a named constant. */

const CFAllocatorRef kCFAllocatorDefault;

/* Default system allocator; you rarely need to use this. */

const CFAllocatorRef kCFAllocatorSystemDefault;

/* This allocator uses malloc(), realloc(), and free(). This should not be
   generally used; stick to kCFAllocatorDefault whenever possible. This
   allocator is useful as the "bytesDeallocator" in CFData or
   "contentsDeallocator" in CFString where the memory was obtained as a
   result of malloc() type functions.
*/

const CFAllocatorRef kCFAllocatorMalloc;

/* This allocator explicitly uses the default malloc zone, returned by
   malloc_default_zone(). It should only be used when an object is
   safe to be allocated in non-scanned memory.
 */

const CFAllocatorRef kCFAllocatorMallocZone;

/* Null allocator which does nothing and allocates no memory. This allocator
   is useful as the "bytesDeallocator" in CFData or "contentsDeallocator"
   in CFString where the memory should not be freed. 
*/

const CFAllocatorRef kCFAllocatorNull;

/* Special allocator argument to CFAllocatorCreate() which means
   "use the functions given in the context to allocate the allocator
   itself as well". 
*/

const CFAllocatorRef kCFAllocatorUseContext;

typedef const void *	(*CFAllocatorRetainCallBack)(const void *info);
typedef void		(*CFAllocatorReleaseCallBack)(const void *info);
typedef CFStringRef	(*CFAllocatorCopyDescriptionCallBack)(const void *info);
typedef void *		(*CFAllocatorAllocateCallBack)(CFIndex allocSize, CFOptionFlags hint, void *info);
typedef void *		(*CFAllocatorReallocateCallBack)(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info);
typedef void		(*CFAllocatorDeallocateCallBack)(void *ptr, void *info);
typedef CFIndex		(*CFAllocatorPreferredSizeCallBack)(CFIndex size, CFOptionFlags hint, void *info);
typedef struct {
    CFIndex				version;
    void *				info;
    CFAllocatorRetainCallBack		retain;
    CFAllocatorReleaseCallBack		release;        
    CFAllocatorCopyDescriptionCallBack	copyDescription;
    CFAllocatorAllocateCallBack		allocate;
    CFAllocatorReallocateCallBack	reallocate;
    CFAllocatorDeallocateCallBack	deallocate;
    CFAllocatorPreferredSizeCallBack	preferredSize;
} CFAllocatorContext;
CFTypeID
CFAllocatorGetTypeID(void);

void CFAllocatorSetDefault(CFAllocatorRef allocator);
CFAllocatorRef CFAllocatorGetDefault(void);
CFAllocatorRef CFAllocatorCreate(CFAllocatorRef allocator, CFAllocatorContext *context);
void *CFAllocatorAllocate(CFAllocatorRef allocator, CFIndex size, CFOptionFlags hint);
void *CFAllocatorReallocate(CFAllocatorRef allocator, void *ptr, CFIndex newsize, CFOptionFlags hint);
void CFAllocatorDeallocate(CFAllocatorRef allocator, void *ptr);
CFIndex CFAllocatorGetPreferredSizeForSize(CFAllocatorRef allocator, CFIndex size, CFOptionFlags hint);
void CFAllocatorGetContext(CFAllocatorRef allocator, CFAllocatorContext *context);

CFTypeID CFGetTypeID(CFTypeRef cf);
CFStringRef CFCopyTypeIDDescription(CFTypeID type_id);
CFTypeRef CFRetain(CFTypeRef cf);
void CFRelease(CFTypeRef cf);
CFIndex CFGetRetainCount(CFTypeRef cf);


CFTypeRef CFMakeCollectable(CFTypeRef cf); // This function is unavailable in ARC mode. Use CFBridgingRelease instead.
Boolean CFEqual(CFTypeRef cf1, CFTypeRef cf2);
CFHashCode CFHash(CFTypeRef cf);
CFStringRef CFCopyDescription(CFTypeRef cf);
CFAllocatorRef CFGetAllocator(CFTypeRef cf);

// ==== CFArray

typedef const void *	(*CFArrayRetainCallBack)(CFAllocatorRef allocator, const void *value);
typedef void		(*CFArrayReleaseCallBack)(CFAllocatorRef allocator, const void *value);
typedef CFStringRef	(*CFArrayCopyDescriptionCallBack)(const void *value);
typedef Boolean		(*CFArrayEqualCallBack)(const void *value1, const void *value2);
typedef struct {
    CFIndex				version;
    CFArrayRetainCallBack		retain;
    CFArrayReleaseCallBack		release;
    CFArrayCopyDescriptionCallBack	copyDescription;
    CFArrayEqualCallBack		equal;
} CFArrayCallBacks;
const CFArrayCallBacks kCFTypeArrayCallBacks;
typedef void (*CFArrayApplierFunction)(const void *value, void *context);
//typedef const struct __CFArray * CFArrayRef;
typedef const CFTypeRef CFArrayRef;
//typedef struct __CFArray * CFMutableArrayRef;
typedef CFTypeRef CFMutableArrayRef;
CFTypeID CFArrayGetTypeID(void);
CFArrayRef CFArrayCreate(CFAllocatorRef allocator, const void **values, CFIndex numValues, const CFArrayCallBacks *callBacks);
CFArrayRef CFArrayCreateCopy(CFAllocatorRef allocator, CFArrayRef theArray);
CFMutableArrayRef CFArrayCreateMutable(CFAllocatorRef allocator, CFIndex capacity, const CFArrayCallBacks *callBacks);
CFMutableArrayRef CFArrayCreateMutableCopy(CFAllocatorRef allocator, CFIndex capacity, CFArrayRef theArray);
CFIndex CFArrayGetCount(CFArrayRef theArray);
CFIndex CFArrayGetCountOfValue(CFArrayRef theArray, CFRange range, const void *value);
Boolean CFArrayContainsValue(CFArrayRef theArray, CFRange range, const void *value);
const void *CFArrayGetValueAtIndex(CFArrayRef theArray, CFIndex idx);
void CFArrayGetValues(CFArrayRef theArray, CFRange range, const void **values);
void CFArrayApplyFunction(CFArrayRef theArray, CFRange range, CFArrayApplierFunction applier, void *context);
CFIndex CFArrayGetFirstIndexOfValue(CFArrayRef theArray, CFRange range, const void *value);
CFIndex CFArrayGetLastIndexOfValue(CFArrayRef theArray, CFRange range, const void *value);
CFIndex CFArrayBSearchValues(CFArrayRef theArray, CFRange range, const void *value, CFComparatorFunction comparator, void *context);
void CFArrayAppendValue(CFMutableArrayRef theArray, const void *value);
void CFArrayInsertValueAtIndex(CFMutableArrayRef theArray, CFIndex idx, const void *value);
void CFArraySetValueAtIndex(CFMutableArrayRef theArray, CFIndex idx, const void *value);
void CFArrayRemoveValueAtIndex(CFMutableArrayRef theArray, CFIndex idx);
void CFArrayRemoveAllValues(CFMutableArrayRef theArray);
void CFArrayReplaceValues(CFMutableArrayRef theArray, CFRange range, const void **newValues, CFIndex newCount);
void CFArrayExchangeValuesAtIndices(CFMutableArrayRef theArray, CFIndex idx1, CFIndex idx2);
void CFArraySortValues(CFMutableArrayRef theArray, CFRange range, CFComparatorFunction comparator, void *context);
void CFArrayAppendArray(CFMutableArrayRef theArray, CFArrayRef otherArray, CFRange otherRange);

// CFDictionary
typedef const void *	(*CFDictionaryRetainCallBack)(CFAllocatorRef allocator, const void *value);
typedef void		(*CFDictionaryReleaseCallBack)(CFAllocatorRef allocator, const void *value);
typedef CFStringRef	(*CFDictionaryCopyDescriptionCallBack)(const void *value);
typedef Boolean		(*CFDictionaryEqualCallBack)(const void *value1, const void *value2);
typedef CFHashCode	(*CFDictionaryHashCallBack)(const void *value);
typedef struct {
    CFIndex				version;
    CFDictionaryRetainCallBack		retain;
    CFDictionaryReleaseCallBack		release;
    CFDictionaryCopyDescriptionCallBack	copyDescription;
    CFDictionaryEqualCallBack		equal;
    CFDictionaryHashCallBack		hash;
} CFDictionaryKeyCallBacks;

const CFDictionaryKeyCallBacks kCFTypeDictionaryKeyCallBacks;
const CFDictionaryKeyCallBacks kCFCopyStringDictionaryKeyCallBacks;


typedef struct {
    CFIndex				version;
    CFDictionaryRetainCallBack		retain;
    CFDictionaryReleaseCallBack		release;
    CFDictionaryCopyDescriptionCallBack	copyDescription;
    CFDictionaryEqualCallBack		equal;
} CFDictionaryValueCallBacks;

const CFDictionaryValueCallBacks kCFTypeDictionaryValueCallBacks;
typedef void (*CFDictionaryApplierFunction)(const void *key, const void *value, void *context);
//typedef const struct __CFDictionary * CFDictionaryRef;
typedef const CFTypeRef CFDictionaryRef;
//typedef struct __CFDictionary * CFMutableDictionaryRef;
typedef CFTypeRef CFMutableDictionaryRef;
CFTypeID CFDictionaryGetTypeID(void);

CFDictionaryRef CFDictionaryCreate(CFAllocatorRef allocator, const void **keys, const void **values, CFIndex numValues, const CFDictionaryKeyCallBacks *keyCallBacks, const CFDictionaryValueCallBacks *valueCallBacks);
CFDictionaryRef CFDictionaryCreateCopy(CFAllocatorRef allocator, CFDictionaryRef theDict);
CFMutableDictionaryRef CFDictionaryCreateMutable(CFAllocatorRef allocator, CFIndex capacity, const CFDictionaryKeyCallBacks *keyCallBacks, const CFDictionaryValueCallBacks *valueCallBacks);
CFMutableDictionaryRef CFDictionaryCreateMutableCopy(CFAllocatorRef allocator, CFIndex capacity, CFDictionaryRef theDict);

CFIndex CFDictionaryGetCount(CFDictionaryRef theDict);
CFIndex CFDictionaryGetCountOfKey(CFDictionaryRef theDict, const void *key);
CFIndex CFDictionaryGetCountOfValue(CFDictionaryRef theDict, const void *value);
Boolean CFDictionaryContainsKey(CFDictionaryRef theDict, const void *key);
Boolean CFDictionaryContainsValue(CFDictionaryRef theDict, const void *value);
const void *CFDictionaryGetValue(CFDictionaryRef theDict, const void *key);
Boolean CFDictionaryGetValueIfPresent(CFDictionaryRef theDict, const void *key, const void **value);
void CFDictionaryGetKeysAndValues(CFDictionaryRef theDict, const void **keys, const void **values);
void CFDictionaryApplyFunction(CFDictionaryRef theDict, CFDictionaryApplierFunction applier, void *context);
void CFDictionaryAddValue(CFMutableDictionaryRef theDict, const void *key, const void *value);


void CFDictionarySetValue(CFMutableDictionaryRef theDict, const void *key, const void *value);
void CFDictionaryReplaceValue(CFMutableDictionaryRef theDict, const void *key, const void *value);
void CFDictionaryRemoveValue(CFMutableDictionaryRef theDict, const void *key);
void CFDictionaryRemoveAllValues(CFMutableDictionaryRef theDict);

// CFData

//typedef const struct __CFData * CFDataRef;
typedef const CFTypeRef CFDataRef;
//typedef struct __CFData * CFMutableDataRef;
typedef CFTypeRef CFMutableDataRef;
CFTypeID CFDataGetTypeID(void);
CFDataRef CFDataCreate(CFAllocatorRef allocator, const UInt8 *bytes, CFIndex length);
CFDataRef CFDataCreateWithBytesNoCopy(CFAllocatorRef allocator, const UInt8 *bytes, CFIndex length, CFAllocatorRef bytesDeallocator);
/* Pass kCFAllocatorNull as bytesDeallocator to assure the bytes aren't freed */
CFDataRef CFDataCreateCopy(CFAllocatorRef allocator, CFDataRef theData);
CFMutableDataRef CFDataCreateMutable(CFAllocatorRef allocator, CFIndex capacity);
CFMutableDataRef CFDataCreateMutableCopy(CFAllocatorRef allocator, CFIndex capacity, CFDataRef theData);
CFIndex CFDataGetLength(CFDataRef theData);
const UInt8 *CFDataGetBytePtr(CFDataRef theData);
UInt8 *CFDataGetMutableBytePtr(CFMutableDataRef theData);
void CFDataGetBytes(CFDataRef theData, CFRange range, UInt8 *buffer); 
void CFDataSetLength(CFMutableDataRef theData, CFIndex length);
void CFDataIncreaseLength(CFMutableDataRef theData, CFIndex extraLength);
void CFDataAppendBytes(CFMutableDataRef theData, const UInt8 *bytes, CFIndex length);
void CFDataReplaceBytes(CFMutableDataRef theData, CFRange range, const UInt8 *newBytes, CFIndex newLength);
void CFDataDeleteBytes(CFMutableDataRef theData, CFRange range);

enum {
    kCFDataSearchBackwards = 1UL << 0,
    kCFDataSearchAnchored = 1UL << 1
};
typedef CFOptionFlags CFDataSearchFlags;
CFRange CFDataFind(CFDataRef theData, CFDataRef dataToFind, CFRange searchRange, CFDataSearchFlags compareOptions);

// CFLocale
//typedef const struct __CFLocale *CFLocaleRef;
typedef const CFTypeRef CFLocaleRef;
CFTypeID CFLocaleGetTypeID(void);
CFLocaleRef CFLocaleGetSystem(void);
CFLocaleRef CFLocaleCopyCurrent(void);
CFArrayRef CFLocaleCopyAvailableLocaleIdentifiers(void);
CFArrayRef CFLocaleCopyISOLanguageCodes(void);
CFArrayRef CFLocaleCopyISOCountryCodes(void);
CFArrayRef CFLocaleCopyISOCurrencyCodes(void);
CFArrayRef CFLocaleCopyCommonISOCurrencyCodes(void);
CFArrayRef CFLocaleCopyPreferredLanguages(void);
CFStringRef CFLocaleCreateCanonicalLanguageIdentifierFromString(CFAllocatorRef allocator, CFStringRef localeIdentifier);
CFStringRef CFLocaleCreateCanonicalLocaleIdentifierFromString(CFAllocatorRef allocator, CFStringRef localeIdentifier);
CFStringRef CFLocaleCreateCanonicalLocaleIdentifierFromScriptManagerCodes(CFAllocatorRef allocator, LangCode lcode, RegionCode rcode);
CFStringRef CFLocaleCreateLocaleIdentifierFromWindowsLocaleCode(CFAllocatorRef allocator, uint32_t lcid);
uint32_t CFLocaleGetWindowsLocaleCodeFromLocaleIdentifier(CFStringRef localeIdentifier);
enum {
    kCFLocaleLanguageDirectionUnknown = 0,
    kCFLocaleLanguageDirectionLeftToRight = 1,
    kCFLocaleLanguageDirectionRightToLeft = 2,
    kCFLocaleLanguageDirectionTopToBottom = 3,
    kCFLocaleLanguageDirectionBottomToTop = 4
};
typedef CFIndex CFLocaleLanguageDirection;
CFLocaleLanguageDirection CFLocaleGetLanguageCharacterDirection(CFStringRef isoLangCode);
CFLocaleLanguageDirection CFLocaleGetLanguageLineDirection(CFStringRef isoLangCode);
CFDictionaryRef CFLocaleCreateComponentsFromLocaleIdentifier(CFAllocatorRef allocator, CFStringRef localeID);
CFStringRef CFLocaleCreateLocaleIdentifierFromComponents(CFAllocatorRef allocator, CFDictionaryRef dictionary);
CFLocaleRef CFLocaleCreate(CFAllocatorRef allocator, CFStringRef localeIdentifier);
CFLocaleRef CFLocaleCreateCopy(CFAllocatorRef allocator, CFLocaleRef locale);
CFStringRef CFLocaleGetIdentifier(CFLocaleRef locale);
CFTypeRef CFLocaleGetValue(CFLocaleRef locale, CFStringRef key);
CFStringRef CFLocaleCopyDisplayNameForPropertyValue(CFLocaleRef displayLocale, CFStringRef key, CFStringRef value);
const CFStringRef kCFLocaleCurrentLocaleDidChangeNotification;
// Locale Keys
const CFStringRef kCFLocaleIdentifier;
const CFStringRef kCFLocaleLanguageCode;
const CFStringRef kCFLocaleCountryCode;
const CFStringRef kCFLocaleScriptCode;
const CFStringRef kCFLocaleVariantCode;
const CFStringRef kCFLocaleExemplarCharacterSet;
const CFStringRef kCFLocaleCalendarIdentifier;
const CFStringRef kCFLocaleCalendar;
const CFStringRef kCFLocaleCollationIdentifier;
const CFStringRef kCFLocaleUsesMetricSystem;
const CFStringRef kCFLocaleMeasurementSystem; // "Metric" or "U.S."
const CFStringRef kCFLocaleDecimalSeparator;
const CFStringRef kCFLocaleGroupingSeparator;
const CFStringRef kCFLocaleCurrencySymbol;
const CFStringRef kCFLocaleCurrencyCode; // ISO 3-letter currency code
const CFStringRef kCFLocaleCollatorIdentifier;
const CFStringRef kCFLocaleQuotationBeginDelimiterKey;
const CFStringRef kCFLocaleQuotationEndDelimiterKey;
const CFStringRef kCFLocaleAlternateQuotationBeginDelimiterKey;
const CFStringRef kCFLocaleAlternateQuotationEndDelimiterKey;
// Values for kCFLocaleCalendarIdentifier
const CFStringRef kCFGregorianCalendar;
const CFStringRef kCFBuddhistCalendar;
const CFStringRef kCFChineseCalendar;
const CFStringRef kCFHebrewCalendar;
const CFStringRef kCFIslamicCalendar;
const CFStringRef kCFIslamicCivilCalendar;
const CFStringRef kCFJapaneseCalendar;
const CFStringRef kCFRepublicOfChinaCalendar;
const CFStringRef kCFPersianCalendar;
const CFStringRef kCFIndianCalendar;
const CFStringRef kCFISO8601Calendar;

// CFCharacterSet

//typedef const struct __CFCharacterSet * CFCharacterSetRef;
typedef const CFTypeRef CFCharacterSetRef;
//typedef struct __CFCharacterSet * CFMutableCharacterSetRef;
typedef CFTypeRef CFMutableCharacterSetRef;
enum {
    kCFCharacterSetControl = 1, /* Control character set (Unicode General Category Cc and Cf) */
    kCFCharacterSetWhitespace, /* Whitespace character set (Unicode General Category Zs and U0009 CHARACTER TABULATION) */
    kCFCharacterSetWhitespaceAndNewline,  /* Whitespace and Newline character set (Unicode General Category Z*, U000A ~ U000D, and U0085) */
    kCFCharacterSetDecimalDigit, /* Decimal digit character set */
    kCFCharacterSetLetter, /* Letter character set (Unicode General Category L* & M*) */
    kCFCharacterSetLowercaseLetter, /* Lowercase character set (Unicode General Category Ll) */
    kCFCharacterSetUppercaseLetter, /* Uppercase character set (Unicode General Category Lu and Lt) */
    kCFCharacterSetNonBase, /* Non-base character set (Unicode General Category M*) */
    kCFCharacterSetDecomposable, /* Canonically decomposable character set */
    kCFCharacterSetAlphaNumeric, /* Alpha Numeric character set (Unicode General Category L*, M*, & N*) */
    kCFCharacterSetPunctuation, /* Punctuation character set (Unicode General Category P*) */
    kCFCharacterSetCapitalizedLetter = 13, /* Titlecase character set (Unicode General Category Lt) */
    kCFCharacterSetSymbol = 14, /* Symbol character set (Unicode General Category S*) */
    kCFCharacterSetNewline = 15, /* Newline character set (U000A ~ U000D, U0085, U2028, and U2029) */
    kCFCharacterSetIllegal = 12/* Illegal character set */
};
typedef CFIndex CFCharacterSetPredefinedSet;
CFTypeID CFCharacterSetGetTypeID(void);
CFCharacterSetRef CFCharacterSetGetPredefined(CFCharacterSetPredefinedSet theSetIdentifier);
CFCharacterSetRef CFCharacterSetCreateWithCharactersInRange(CFAllocatorRef alloc, CFRange theRange);
CFCharacterSetRef CFCharacterSetCreateWithCharactersInString(CFAllocatorRef alloc, CFStringRef theString);
CFCharacterSetRef CFCharacterSetCreateWithBitmapRepresentation(CFAllocatorRef alloc, CFDataRef theData);
CFCharacterSetRef CFCharacterSetCreateInvertedSet(CFAllocatorRef alloc, CFCharacterSetRef theSet);
Boolean CFCharacterSetIsSupersetOfSet(CFCharacterSetRef theSet, CFCharacterSetRef theOtherset);
Boolean CFCharacterSetHasMemberInPlane(CFCharacterSetRef theSet, CFIndex thePlane);
CFMutableCharacterSetRef CFCharacterSetCreateMutable(CFAllocatorRef alloc);
CFCharacterSetRef CFCharacterSetCreateCopy(CFAllocatorRef alloc, CFCharacterSetRef theSet);
CFMutableCharacterSetRef CFCharacterSetCreateMutableCopy(CFAllocatorRef alloc, CFCharacterSetRef theSet);
Boolean CFCharacterSetIsCharacterMember(CFCharacterSetRef theSet, UniChar theChar);
Boolean CFCharacterSetIsLongCharacterMember(CFCharacterSetRef theSet, UTF32Char theChar);
CFDataRef CFCharacterSetCreateBitmapRepresentation(CFAllocatorRef alloc, CFCharacterSetRef theSet);
void CFCharacterSetAddCharactersInRange(CFMutableCharacterSetRef theSet, CFRange theRange);
void CFCharacterSetRemoveCharactersInRange(CFMutableCharacterSetRef theSet, CFRange theRange);
void CFCharacterSetAddCharactersInString(CFMutableCharacterSetRef theSet,  CFStringRef theString);
void CFCharacterSetRemoveCharactersInString(CFMutableCharacterSetRef theSet, CFStringRef theString);
void CFCharacterSetUnion(CFMutableCharacterSetRef theSet, CFCharacterSetRef theOtherSet);
void CFCharacterSetIntersect(CFMutableCharacterSetRef theSet, CFCharacterSetRef theOtherSet);
void CFCharacterSetInvert(CFMutableCharacterSetRef theSet);


// CFString

typedef UInt32 CFStringEncoding;

enum {
    kCFStringEncodingMacRoman = 0,
    kCFStringEncodingWindowsLatin1 = 0x0500, 
    kCFStringEncodingISOLatin1 = 0x0201, 
    kCFStringEncodingNextStepLatin = 0x0B01, 
    kCFStringEncodingASCII = 0x0600, 
    kCFStringEncodingUnicode = 0x0100, 
    kCFStringEncodingUTF8 = 0x08000100, 
    kCFStringEncodingNonLossyASCII = 0x0BFF, 

    kCFStringEncodingUTF16 = 0x0100, 
    kCFStringEncodingUTF16BE = 0x10000100, 
    kCFStringEncodingUTF16LE = 0x14000100, 

    kCFStringEncodingUTF32 = 0x0c000100, 
    kCFStringEncodingUTF32BE = 0x18000100, 
    kCFStringEncodingUTF32LE = 0x1c000100 
};
typedef CFStringEncoding CFStringBuiltInEncodings;


CFTypeID CFStringGetTypeID(void);

CFStringRef CFStringCreateWithPascalString(CFAllocatorRef alloc, ConstStr255Param pStr, CFStringEncoding encoding);
CFStringRef CFStringCreateWithCString(CFAllocatorRef alloc, const char *cStr, CFStringEncoding encoding);
CFStringRef CFStringCreateWithBytes(CFAllocatorRef alloc, const UInt8 *bytes, CFIndex numBytes, CFStringEncoding encoding, Boolean isExternalRepresentation);
CFStringRef CFStringCreateWithCharacters(CFAllocatorRef alloc, const UniChar *chars, CFIndex numChars);

CFStringRef CFStringCreateWithPascalStringNoCopy(CFAllocatorRef alloc, ConstStr255Param pStr, CFStringEncoding encoding, CFAllocatorRef contentsDeallocator);
CFStringRef CFStringCreateWithCStringNoCopy(CFAllocatorRef alloc, const char *cStr, CFStringEncoding encoding, CFAllocatorRef contentsDeallocator);
CFStringRef CFStringCreateWithBytesNoCopy(CFAllocatorRef alloc, const UInt8 *bytes, CFIndex numBytes, CFStringEncoding encoding, Boolean isExternalRepresentation, CFAllocatorRef contentsDeallocator);
CFStringRef CFStringCreateWithCharactersNoCopy(CFAllocatorRef alloc, const UniChar *chars, CFIndex numChars, CFAllocatorRef contentsDeallocator);

CFStringRef CFStringCreateWithSubstring(CFAllocatorRef alloc, CFStringRef str, CFRange range);
CFStringRef CFStringCreateCopy(CFAllocatorRef alloc, CFStringRef theString);
CFStringRef CFStringCreateWithFormat(CFAllocatorRef alloc, CFDictionaryRef formatOptions, CFStringRef format, ...);
CFStringRef CFStringCreateWithFormatAndArguments(CFAllocatorRef alloc, CFDictionaryRef formatOptions, CFStringRef format, va_list arguments);

CFMutableStringRef CFStringCreateMutable(CFAllocatorRef alloc, CFIndex maxLength);
CFMutableStringRef CFStringCreateMutableCopy(CFAllocatorRef alloc, CFIndex maxLength, CFStringRef theString);
CFMutableStringRef CFStringCreateMutableWithExternalCharactersNoCopy(CFAllocatorRef alloc, UniChar *chars, CFIndex numChars, CFIndex capacity, CFAllocatorRef externalCharactersAllocator);

CFIndex CFStringGetLength(CFStringRef theString);
UniChar CFStringGetCharacterAtIndex(CFStringRef theString, CFIndex idx);
void CFStringGetCharacters(CFStringRef theString, CFRange range, UniChar *buffer);

Boolean CFStringGetPascalString(CFStringRef theString, StringPtr buffer, CFIndex bufferSize, CFStringEncoding encoding);
Boolean CFStringGetCString(CFStringRef theString, char *buffer, CFIndex bufferSize, CFStringEncoding encoding);

ConstStringPtr CFStringGetPascalStringPtr(CFStringRef theString, CFStringEncoding encoding);	
const char *CFStringGetCStringPtr(CFStringRef theString, CFStringEncoding encoding);		
const UniChar *CFStringGetCharactersPtr(CFStringRef theString);					

CFIndex CFStringGetBytes(CFStringRef theString, CFRange range, CFStringEncoding encoding, UInt8 lossByte, Boolean isExternalRepresentation, UInt8 *buffer, CFIndex maxBufLen, CFIndex *usedBufLen);
CFStringRef CFStringCreateFromExternalRepresentation(CFAllocatorRef alloc, CFDataRef data, CFStringEncoding encoding);	
CFDataRef CFStringCreateExternalRepresentation(CFAllocatorRef alloc, CFStringRef theString, CFStringEncoding encoding, UInt8 lossByte);		

CFStringEncoding CFStringGetSmallestEncoding(CFStringRef theString);	
CFStringEncoding CFStringGetFastestEncoding(CFStringRef theString);	
CFStringEncoding CFStringGetSystemEncoding(void);		
CFIndex CFStringGetMaximumSizeForEncoding(CFIndex length, CFStringEncoding encoding);	

Boolean CFStringGetFileSystemRepresentation(CFStringRef string, char *buffer, CFIndex maxBufLen);
CFIndex CFStringGetMaximumSizeOfFileSystemRepresentation(CFStringRef string);
CFStringRef CFStringCreateWithFileSystemRepresentation(CFAllocatorRef alloc, const char *buffer);


enum {	
    kCFCompareCaseInsensitive = 1,	
    kCFCompareBackwards = 4,		
    kCFCompareAnchored = 8,		
    kCFCompareNonliteral = 16,		
    kCFCompareLocalized = 32,		
    kCFCompareNumerically = 64,
    kCFCompareDiacriticInsensitive = 128, 
    kCFCompareWidthInsensitive = 256, 
    kCFCompareForcedOrdering = 512 
};
typedef CFOptionFlags CFStringCompareFlags;

CFComparisonResult CFStringCompareWithOptionsAndLocale(CFStringRef theString1, CFStringRef theString2, CFRange rangeToCompare, CFStringCompareFlags compareOptions, CFLocaleRef locale);
CFComparisonResult CFStringCompareWithOptions(CFStringRef theString1, CFStringRef theString2, CFRange rangeToCompare, CFStringCompareFlags compareOptions);
CFComparisonResult CFStringCompare(CFStringRef theString1, CFStringRef theString2, CFStringCompareFlags compareOptions);
Boolean CFStringFindWithOptionsAndLocale(CFStringRef theString, CFStringRef stringToFind, CFRange rangeToSearch, CFStringCompareFlags searchOptions, CFLocaleRef locale, CFRange *result);

Boolean CFStringFindWithOptions(CFStringRef theString, CFStringRef stringToFind, CFRange rangeToSearch, CFStringCompareFlags searchOptions, CFRange *result);

CFArrayRef CFStringCreateArrayWithFindResults(CFAllocatorRef alloc, CFStringRef theString, CFStringRef stringToFind, CFRange rangeToSearch, CFStringCompareFlags compareOptions);

CFRange CFStringFind(CFStringRef theString, CFStringRef stringToFind, CFStringCompareFlags compareOptions);
Boolean CFStringHasPrefix(CFStringRef theString, CFStringRef prefix);
Boolean CFStringHasSuffix(CFStringRef theString, CFStringRef suffix);


CFRange CFStringGetRangeOfComposedCharactersAtIndex(CFStringRef theString, CFIndex theIndex);


Boolean CFStringFindCharacterFromSet(CFStringRef theString, CFCharacterSetRef theSet, CFRange rangeToSearch, CFStringCompareFlags searchOptions, CFRange *result);


void CFStringGetLineBounds(CFStringRef theString, CFRange range, CFIndex *lineBeginIndex, CFIndex *lineEndIndex, CFIndex *contentsEndIndex); 
void CFStringGetParagraphBounds(CFStringRef string, CFRange range, CFIndex *parBeginIndex, CFIndex *parEndIndex, CFIndex *contentsEndIndex);

CFIndex CFStringGetHyphenationLocationBeforeIndex(CFStringRef string, CFIndex location, CFRange limitRange, CFOptionFlags options, CFLocaleRef locale, UTF32Char *character);
Boolean CFStringIsHyphenationAvailableForLocale(CFLocaleRef locale);

CFStringRef CFStringCreateByCombiningStrings(CFAllocatorRef alloc, CFArrayRef theArray, CFStringRef separatorString);	
CFArrayRef CFStringCreateArrayBySeparatingStrings(CFAllocatorRef alloc, CFStringRef theString, CFStringRef separatorString);	

SInt32 CFStringGetIntValue(CFStringRef str);		
double CFStringGetDoubleValue(CFStringRef str);	

void CFStringAppend(CFMutableStringRef theString, CFStringRef appendedString);
void CFStringAppendCharacters(CFMutableStringRef theString, const UniChar *chars, CFIndex numChars);
void CFStringAppendPascalString(CFMutableStringRef theString, ConstStr255Param pStr, CFStringEncoding encoding);
void CFStringAppendCString(CFMutableStringRef theString, const char *cStr, CFStringEncoding encoding);
void CFStringAppendFormat(CFMutableStringRef theString, CFDictionaryRef formatOptions, CFStringRef format, ...);
void CFStringAppendFormatAndArguments(CFMutableStringRef theString, CFDictionaryRef formatOptions, CFStringRef format, va_list arguments);
void CFStringInsert(CFMutableStringRef str, CFIndex idx, CFStringRef insertedStr);
void CFStringDelete(CFMutableStringRef theString, CFRange range);
void CFStringReplace(CFMutableStringRef theString, CFRange range, CFStringRef replacement);
void CFStringReplaceAll(CFMutableStringRef theString, CFStringRef replacement);	
CFIndex CFStringFindAndReplace(CFMutableStringRef theString, CFStringRef stringToFind, CFStringRef replacementString, CFRange rangeToSearch, CFStringCompareFlags compareOptions);

void CFStringSetExternalCharactersNoCopy(CFMutableStringRef theString, UniChar *chars, CFIndex length, CFIndex capacity);	
void CFStringPad(CFMutableStringRef theString, CFStringRef padString, CFIndex length, CFIndex indexIntoPad);
void CFStringTrim(CFMutableStringRef theString, CFStringRef trimString);
void CFStringTrimWhitespace(CFMutableStringRef theString);
void CFStringLowercase(CFMutableStringRef theString, CFLocaleRef locale);
void CFStringUppercase(CFMutableStringRef theString, CFLocaleRef locale);
void CFStringCapitalize(CFMutableStringRef theString, CFLocaleRef locale);


enum {
	kCFStringNormalizationFormD = 0, // Canonical Decomposition
	kCFStringNormalizationFormKD, // Compatibility Decomposition
	kCFStringNormalizationFormC, // Canonical Decomposition followed by Canonical Composition
	kCFStringNormalizationFormKC // Compatibility Decomposition followed by Canonical Composition
};
typedef CFIndex CFStringNormalizationForm;

void CFStringNormalize(CFMutableStringRef theString, CFStringNormalizationForm theForm);

void CFStringFold(CFMutableStringRef theString, CFOptionFlags theFlags, CFLocaleRef theLocale);
Boolean CFStringTransform(CFMutableStringRef string, CFRange *range, CFStringRef transform, Boolean reverse);


const CFStringRef kCFStringTransformStripCombiningMarks;
const CFStringRef kCFStringTransformToLatin;
const CFStringRef kCFStringTransformFullwidthHalfwidth;
const CFStringRef kCFStringTransformLatinKatakana;
const CFStringRef kCFStringTransformLatinHiragana;
const CFStringRef kCFStringTransformHiraganaKatakana;
const CFStringRef kCFStringTransformMandarinLatin;
const CFStringRef kCFStringTransformLatinHangul;
const CFStringRef kCFStringTransformLatinArabic;
const CFStringRef kCFStringTransformLatinHebrew;
const CFStringRef kCFStringTransformLatinThai;
const CFStringRef kCFStringTransformLatinCyrillic;
const CFStringRef kCFStringTransformLatinGreek;
const CFStringRef kCFStringTransformToXMLHex;
const CFStringRef kCFStringTransformToUnicodeName;
const CFStringRef kCFStringTransformStripDiacritics;

Boolean CFStringIsEncodingAvailable(CFStringEncoding encoding);
const CFStringEncoding *CFStringGetListOfAvailableEncodings(void);
CFStringRef CFStringGetNameOfEncoding(CFStringEncoding encoding);
unsigned long CFStringConvertEncodingToNSStringEncoding(CFStringEncoding encoding);
CFStringEncoding CFStringConvertNSStringEncodingToEncoding(unsigned long encoding);
UInt32 CFStringConvertEncodingToWindowsCodepage(CFStringEncoding encoding);
CFStringEncoding CFStringConvertWindowsCodepageToEncoding(UInt32 codepage);
CFStringEncoding CFStringConvertIANACharSetNameToEncoding(CFStringRef theString);
CFStringRef  CFStringConvertEncodingToIANACharSetName(CFStringEncoding encoding);
CFStringEncoding CFStringGetMostCompatibleMacStringEncoding(CFStringEncoding encoding);

void CFShow(CFTypeRef obj);
void CFShowStr(CFStringRef str);

// CFError
typedef CFTypeRef CFErrorRef;
CFTypeID CFErrorGetTypeID(void);
// Predefined domains; value of "code" will correspond to preexisting values in these domains.
const CFStringRef kCFErrorDomainPOSIX;
const CFStringRef kCFErrorDomainOSStatus;
const CFStringRef kCFErrorDomainMach;
const CFStringRef kCFErrorDomainCocoa;
// Keys in userInfo for localizable, end-user presentable error messages. At minimum provide one of first two; ideally provide all three.
const CFStringRef kCFErrorLocalizedDescriptionKey        ;   // Key to identify the end user-presentable description in userInfo.
const CFStringRef kCFErrorLocalizedFailureReasonKey      ;   // Key to identify the end user-presentable failure reason in userInfo.
const CFStringRef kCFErrorLocalizedRecoverySuggestionKey ;   // Key to identify the end user-presentable recovery suggestion in userInfo.
// If you do not have localizable error strings, you can provide a value for this key instead.
const CFStringRef kCFErrorDescriptionKey                 ;   // Key to identify the description in the userInfo dictionary. Should be a complete sentence if possible. Should not contain domain name or error code.
// Other keys in userInfo.
const CFStringRef kCFErrorUnderlyingErrorKey             ;   // Key to identify the underlying error in userInfo.
const CFStringRef kCFErrorURLKey                         ;    // Key to identify associated URL in userInfo.  Typically one of this or kCFErrorFilePathKey is provided.
const CFStringRef kCFErrorFilePathKey                    ;    // Key to identify associated file path in userInfo.    Typically one of this or kCFErrorURLKey is provided.
CFErrorRef CFErrorCreate(CFAllocatorRef allocator, CFStringRef domain, CFIndex code, CFDictionaryRef userInfo);
CFErrorRef CFErrorCreateWithUserInfoKeysAndValues(CFAllocatorRef allocator, CFStringRef domain, CFIndex code, const void *const *userInfoKeys, const void *const *userInfoValues, CFIndex numUserInfoValues);
CFStringRef CFErrorGetDomain(CFErrorRef err);
CFIndex CFErrorGetCode(CFErrorRef err);
CFDictionaryRef CFErrorCopyUserInfo(CFErrorRef err);
CFStringRef CFErrorCopyDescription(CFErrorRef err);
CFStringRef CFErrorCopyFailureReason(CFErrorRef err);
CFStringRef CFErrorCopyRecoverySuggestion(CFErrorRef err);

// CFURL
enum {
    kCFURLPOSIXPathStyle = 0,
    kCFURLHFSPathStyle,
    kCFURLWindowsPathStyle
};
typedef CFIndex CFURLPathStyle;
typedef const struct __CFURL * CFURLRef;
CFTypeID CFURLGetTypeID(void);
CFURLRef CFURLCreateWithBytes(CFAllocatorRef allocator, const UInt8 *URLBytes, CFIndex length, CFStringEncoding encoding, CFURLRef baseURL);
CFDataRef CFURLCreateData(CFAllocatorRef allocator, CFURLRef url, CFStringEncoding encoding, Boolean escapeWhitespace);
CFURLRef CFURLCreateWithString(CFAllocatorRef allocator, CFStringRef URLString, CFURLRef baseURL);
CFURLRef CFURLCreateAbsoluteURLWithBytes(CFAllocatorRef alloc, const UInt8 *relativeURLBytes, CFIndex length, CFStringEncoding encoding, CFURLRef baseURL, Boolean useCompatibilityMode);
CFURLRef CFURLCreateWithFileSystemPath(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory);
CFURLRef CFURLCreateFromFileSystemRepresentation(CFAllocatorRef allocator, const UInt8 *buffer, CFIndex bufLen, Boolean isDirectory);
CFURLRef CFURLCreateWithFileSystemPathRelativeToBase(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory, CFURLRef baseURL); 
CFURLRef CFURLCreateFromFileSystemRepresentationRelativeToBase(CFAllocatorRef allocator, const UInt8 *buffer, CFIndex bufLen, Boolean isDirectory, CFURLRef baseURL);
                                                                         
Boolean CFURLGetFileSystemRepresentation(CFURLRef url, Boolean resolveAgainstBase, UInt8 *buffer, CFIndex maxBufLen);
CFURLRef CFURLCopyAbsoluteURL(CFURLRef relativeURL);
CFStringRef CFURLGetString(CFURLRef anURL);
CFURLRef CFURLGetBaseURL(CFURLRef anURL);
Boolean CFURLCanBeDecomposed(CFURLRef anURL); 
CFStringRef CFURLCopyScheme(CFURLRef anURL);
CFStringRef CFURLCopyNetLocation(CFURLRef anURL); 
CFStringRef CFURLCopyPath(CFURLRef anURL);
CFStringRef CFURLCopyStrictPath(CFURLRef anURL, Boolean *isAbsolute);
CFStringRef CFURLCopyFileSystemPath(CFURLRef anURL, CFURLPathStyle pathStyle);
Boolean CFURLHasDirectoryPath(CFURLRef anURL);
CFStringRef CFURLCopyResourceSpecifier(CFURLRef anURL); 
CFStringRef CFURLCopyHostName(CFURLRef anURL);
SInt32 CFURLGetPortNumber(CFURLRef anURL); 
CFStringRef CFURLCopyUserName(CFURLRef anURL);
CFStringRef CFURLCopyPassword(CFURLRef anURL);
CFStringRef CFURLCopyParameterString(CFURLRef anURL, CFStringRef charactersToLeaveEscaped);
CFStringRef CFURLCopyQueryString(CFURLRef anURL, CFStringRef charactersToLeaveEscaped);
CFStringRef CFURLCopyFragment(CFURLRef anURL, CFStringRef charactersToLeaveEscaped);
CFStringRef CFURLCopyLastPathComponent(CFURLRef url);
CFStringRef CFURLCopyPathExtension(CFURLRef url);
CFURLRef CFURLCreateCopyAppendingPathComponent(CFAllocatorRef allocator, CFURLRef url, CFStringRef pathComponent, Boolean isDirectory);
CFURLRef CFURLCreateCopyDeletingLastPathComponent(CFAllocatorRef allocator, CFURLRef url);
CFURLRef CFURLCreateCopyAppendingPathExtension(CFAllocatorRef allocator, CFURLRef url, CFStringRef extension);
CFURLRef CFURLCreateCopyDeletingPathExtension(CFAllocatorRef allocator, CFURLRef url);
 
CFIndex CFURLGetBytes(CFURLRef url, UInt8 *buffer, CFIndex bufferLength);
enum {
	kCFURLComponentScheme = 1,
	kCFURLComponentNetLocation = 2,
	kCFURLComponentPath = 3,
	kCFURLComponentResourceSpecifier = 4,
	kCFURLComponentUser = 5,
	kCFURLComponentPassword = 6,
	kCFURLComponentUserInfo = 7,
	kCFURLComponentHost = 8,
	kCFURLComponentPort = 9,
	kCFURLComponentParameterString = 10,
	kCFURLComponentQuery = 11,
	kCFURLComponentFragment = 12
};
typedef CFIndex CFURLComponentType;
 
CFRange CFURLGetByteRangeForComponent(CFURLRef url, CFURLComponentType component, CFRange *rangeIncludingSeparators);
CFStringRef CFURLCreateStringByReplacingPercentEscapes(CFAllocatorRef allocator, CFStringRef originalString, CFStringRef charactersToLeaveEscaped);
CFStringRef CFURLCreateStringByReplacingPercentEscapesUsingEncoding(CFAllocatorRef allocator, CFStringRef origString, CFStringRef charsToLeaveEscaped, CFStringEncoding encoding);
CFStringRef CFURLCreateStringByAddingPercentEscapes(CFAllocatorRef allocator, CFStringRef originalString, CFStringRef charactersToLeaveUnescaped, CFStringRef legalURLCharactersToBeEscaped, CFStringEncoding encoding);
CFURLRef CFURLCreateFileReferenceURL(CFAllocatorRef allocator, CFURLRef url, CFErrorRef *error);
CFURLRef CFURLCreateFilePathURL(CFAllocatorRef allocator, CFURLRef url, CFErrorRef *error);

Boolean CFURLCopyResourcePropertyForKey(CFURLRef url, CFStringRef key, void *propertyValueTypeRefPtr, CFErrorRef *error);
CFDictionaryRef CFURLCopyResourcePropertiesForKeys(CFURLRef url, CFArrayRef keys, CFErrorRef *error);
Boolean CFURLSetResourcePropertyForKey(CFURLRef url, CFStringRef key, CFTypeRef propertyValue, CFErrorRef *error);
Boolean CFURLSetResourcePropertiesForKeys(CFURLRef url, CFDictionaryRef keyedPropertyValues, CFErrorRef *error);
const CFStringRef kCFURLKeysOfUnsetValuesKey;
void CFURLClearResourcePropertyCacheForKey(CFURLRef url, CFStringRef key);
void CFURLClearResourcePropertyCache(CFURLRef url);
void CFURLSetTemporaryResourcePropertyForKey(CFURLRef url, CFStringRef key, CFTypeRef propertyValue);
Boolean CFURLResourceIsReachable(CFURLRef url, CFErrorRef *error);
const CFStringRef kCFURLNameKey;
const CFStringRef kCFURLLocalizedNameKey;
const CFStringRef kCFURLIsRegularFileKey;
const CFStringRef kCFURLIsDirectoryKey;
const CFStringRef kCFURLIsSymbolicLinkKey;
const CFStringRef kCFURLIsVolumeKey;
const CFStringRef kCFURLIsPackageKey;
const CFStringRef kCFURLIsSystemImmutableKey;
const CFStringRef kCFURLIsUserImmutableKey;
const CFStringRef kCFURLIsHiddenKey;
const CFStringRef kCFURLHasHiddenExtensionKey;
const CFStringRef kCFURLCreationDateKey;
const CFStringRef kCFURLContentAccessDateKey;
const CFStringRef kCFURLContentModificationDateKey;
const CFStringRef kCFURLAttributeModificationDateKey;
const CFStringRef kCFURLLinkCountKey;
const CFStringRef kCFURLParentDirectoryURLKey;
const CFStringRef kCFURLVolumeURLKey;
const CFStringRef kCFURLTypeIdentifierKey;
const CFStringRef kCFURLLocalizedTypeDescriptionKey;
const CFStringRef kCFURLLabelNumberKey;
const CFStringRef kCFURLLabelColorKey;
const CFStringRef kCFURLLocalizedLabelKey;
const CFStringRef kCFURLEffectiveIconKey;
const CFStringRef kCFURLCustomIconKey;
const CFStringRef kCFURLFileResourceIdentifierKey;
const CFStringRef kCFURLVolumeIdentifierKey;
const CFStringRef kCFURLPreferredIOBlockSizeKey;
const CFStringRef kCFURLIsReadableKey;
const CFStringRef kCFURLIsWritableKey;
const CFStringRef kCFURLIsExecutableKey;
const CFStringRef kCFURLFileSecurityKey;
const CFStringRef kCFURLFileResourceTypeKey;
const CFStringRef kCFURLFileResourceTypeNamedPipe;
const CFStringRef kCFURLFileResourceTypeCharacterSpecial;
const CFStringRef kCFURLFileResourceTypeDirectory;
const CFStringRef kCFURLFileResourceTypeBlockSpecial;
const CFStringRef kCFURLFileResourceTypeRegular;
const CFStringRef kCFURLFileResourceTypeSymbolicLink;
const CFStringRef kCFURLFileResourceTypeSocket;
const CFStringRef kCFURLFileResourceTypeUnknown;
const CFStringRef kCFURLFileSizeKey;
const CFStringRef kCFURLFileAllocatedSizeKey;
const CFStringRef kCFURLTotalFileSizeKey;
const CFStringRef kCFURLTotalFileAllocatedSizeKey;
const CFStringRef kCFURLIsAliasFileKey;
const CFStringRef kCFURLIsMountTriggerKey;
const CFStringRef kCFURLVolumeLocalizedFormatDescriptionKey;
const CFStringRef kCFURLVolumeTotalCapacityKey;
const CFStringRef kCFURLVolumeAvailableCapacityKey;
const CFStringRef kCFURLVolumeResourceCountKey;
const CFStringRef kCFURLVolumeSupportsPersistentIDsKey;
const CFStringRef kCFURLVolumeSupportsSymbolicLinksKey;
const CFStringRef kCFURLVolumeSupportsHardLinksKey;
const CFStringRef kCFURLVolumeSupportsJournalingKey;
const CFStringRef kCFURLVolumeIsJournalingKey;
const CFStringRef kCFURLVolumeSupportsSparseFilesKey;
const CFStringRef kCFURLVolumeSupportsZeroRunsKey;
const CFStringRef kCFURLVolumeSupportsCaseSensitiveNamesKey;
const CFStringRef kCFURLVolumeSupportsCasePreservedNamesKey;
const CFStringRef kCFURLVolumeSupportsRootDirectoryDatesKey;
const CFStringRef kCFURLVolumeSupportsVolumeSizesKey;
const CFStringRef kCFURLVolumeSupportsRenamingKey;
const CFStringRef kCFURLVolumeSupportsAdvisoryFileLockingKey;
const CFStringRef kCFURLVolumeSupportsExtendedSecurityKey;
const CFStringRef kCFURLVolumeIsBrowsableKey;
const CFStringRef kCFURLVolumeMaximumFileSizeKey;
const CFStringRef kCFURLVolumeIsEjectableKey;
const CFStringRef kCFURLVolumeIsRemovableKey;
const CFStringRef kCFURLVolumeIsInternalKey;
const CFStringRef kCFURLVolumeIsAutomountedKey;
const CFStringRef kCFURLVolumeIsLocalKey;
const CFStringRef kCFURLVolumeIsReadOnlyKey;
const CFStringRef kCFURLVolumeCreationDateKey;
const CFStringRef kCFURLVolumeURLForRemountingKey;
const CFStringRef kCFURLVolumeUUIDStringKey;
const CFStringRef kCFURLVolumeNameKey;
const CFStringRef kCFURLVolumeLocalizedNameKey;
const CFStringRef kCFURLIsUbiquitousItemKey;
const CFStringRef kCFURLUbiquitousItemHasUnresolvedConflictsKey;
const CFStringRef kCFURLUbiquitousItemIsDownloadedKey;
const CFStringRef kCFURLUbiquitousItemIsDownloadingKey;
const CFStringRef kCFURLUbiquitousItemIsUploadedKey;
const CFStringRef kCFURLUbiquitousItemIsUploadingKey;
const CFStringRef kCFURLUbiquitousItemPercentDownloadedKey;
const CFStringRef kCFURLUbiquitousItemPercentUploadedKey;
enum {
    kCFURLBookmarkCreationPreferFileIDResolutionMask = ( 1UL << 8 ),  // At resolution time, this alias will prefer resolving by the embedded fileID to the path
    kCFURLBookmarkCreationMinimalBookmarkMask = ( 1UL << 9 ), // Creates a bookmark with "less" information, which may be smaller but still be able to resolve in certain ways
    kCFURLBookmarkCreationSuitableForBookmarkFile = ( 1UL << 10 ), // includes in the created bookmark those properties which are needed for a bookmark/alias file
};

enum {
    kCFURLBookmarkCreationWithSecurityScope = ( 1UL << 11 ), // Mac OS X 10.7.3 and later, include information in the bookmark data which allows the same sandboxed process to access the resource after being relaunched
    kCFURLBookmarkCreationSecurityScopeAllowOnlyReadAccess = ( 1UL << 12 ), // Mac OS X 10.7.3 and later, if used with kCFURLBookmarkCreationWithSecurityScope, at resolution time only read access to the resource will be granted
};

typedef CFOptionFlags CFURLBookmarkCreationOptions;
enum  {
    kCFBookmarkResolutionWithoutUIMask = ( 1UL << 8 ),		// don't perform any UI during bookmark resolution
    kCFBookmarkResolutionWithoutMountingMask = ( 1UL << 9 ),	// don't mount a volume during bookmark resolution
};
enum {
    kCFURLBookmarkResolutionWithSecurityScope = ( 1UL << 10 ), // Mac OS X 10.7.3 and later, extract the security scope included at creation time to provide the ability to access the resource.
};

typedef CFOptionFlags CFURLBookmarkResolutionOptions;
typedef CFOptionFlags CFURLBookmarkFileCreationOptions;
CFDataRef CFURLCreateBookmarkData ( CFAllocatorRef allocator, CFURLRef url, CFURLBookmarkCreationOptions options, CFArrayRef resourcePropertiesToInclude, CFURLRef relativeToURL, CFErrorRef* error );
CFURLRef CFURLCreateByResolvingBookmarkData ( CFAllocatorRef allocator, CFDataRef bookmark, CFURLBookmarkResolutionOptions options, CFURLRef relativeToURL, CFArrayRef resourcePropertiesToInclude, Boolean* isStale, CFErrorRef* error );
CFDictionaryRef CFURLCreateResourcePropertiesForKeysFromBookmarkData ( CFAllocatorRef allocator, CFArrayRef resourcePropertiesToReturn, CFDataRef bookmark );
CFTypeRef  CFURLCreateResourcePropertyForKeyFromBookmarkData( CFAllocatorRef allocator, CFStringRef resourcePropertyKey, CFDataRef bookmark );
CFDataRef CFURLCreateBookmarkDataFromFile(CFAllocatorRef allocator, CFURLRef fileURL, CFErrorRef *errorRef );
Boolean CFURLWriteBookmarkDataToFile( CFDataRef bookmarkRef, CFURLRef fileURL, CFURLBookmarkFileCreationOptions options, CFErrorRef *errorRef );
CFDataRef CFURLCreateBookmarkDataFromAliasRecord ( CFAllocatorRef allocatorRef, CFDataRef aliasRecordDataRef );
Boolean CFURLStartAccessingSecurityScopedResource(CFURLRef url); // Available in MacOS X 10.7.3 and later
void CFURLStopAccessingSecurityScopedResource(CFURLRef url);

enum __CFByteOrder {
    CFByteOrderUnknown,
    CFByteOrderLittleEndian,
    CFByteOrderBigEndian
};
typedef CFIndex CFByteOrder;

]])

return ffi.load("/System/Library/CoreFoundation.framework/CoreFoundation")
