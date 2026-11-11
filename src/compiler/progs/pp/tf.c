/* true and false in #if: 1 and 0 from C23 on (gcc 16's default std,
   gnu23: libcpp's true_false), plain identifiers, so 0, before it
   (-std=gnu11: tf-gnu11.i). gnulib's file-has-acl.c has
   #define USE_LINUX_XATTR true ... #if USE_LINUX_XATTR */
#define USE_IT true
#if true
int true_is_one;
#else
int true_is_zero;
#endif
#if false || !true
int false_is_one;
#else
int false_is_zero;
#endif
#if USE_IT
int through_a_macro;
#endif
#if defined true
int true_is_a_macro;
#endif
