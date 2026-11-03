/* made by src/glibc/mkgccrtfixed.pl: arm's fixed-bit.c, every function */
typedef long _Accum DAtype;
typedef long long DQtype;
typedef short _Accum HAtype;
typedef _Fract HQtype;
typedef short _Fract QQtype;
typedef _Accum SAtype;
typedef long _Fract SQtype;
typedef unsigned long _Accum UDAtype;
typedef unsigned long long UDQtype;
typedef unsigned short _Accum UHAtype;
typedef unsigned _Fract UHQtype;
typedef unsigned short _Fract UQQtype;
typedef unsigned _Accum USAtype;
typedef unsigned long _Fract USQtype;
typedef long long DItype;
typedef short HItype;
typedef signed char QItype;
typedef int SItype;
typedef unsigned long long UDItype;
typedef unsigned short UHItype;
typedef unsigned char UQItype;
typedef unsigned int USItype;
typedef float SFtype;
typedef double DFtype;
typedef int word_type;
union fxuDA { DAtype f; unsigned long long u; };
static DAtype fxmDA (unsigned long long p) { union fxuDA v; v.u = p; return v.f; }
static unsigned long long fxbDA (DAtype x) { union fxuDA v; v.u = 0; v.f = x; return v.u; }
union fxuDQ { DQtype f; unsigned long long u; };
static DQtype fxmDQ (unsigned long long p) { union fxuDQ v; v.u = p; return v.f; }
static unsigned long long fxbDQ (DQtype x) { union fxuDQ v; v.u = 0; v.f = x; return v.u; }
union fxuHA { HAtype f; unsigned long long u; };
static HAtype fxmHA (unsigned long long p) { union fxuHA v; v.u = p; return v.f; }
static unsigned long long fxbHA (HAtype x) { union fxuHA v; v.u = 0; v.f = x; return v.u; }
union fxuHQ { HQtype f; unsigned long long u; };
static HQtype fxmHQ (unsigned long long p) { union fxuHQ v; v.u = p; return v.f; }
static unsigned long long fxbHQ (HQtype x) { union fxuHQ v; v.u = 0; v.f = x; return v.u; }
union fxuQQ { QQtype f; unsigned long long u; };
static QQtype fxmQQ (unsigned long long p) { union fxuQQ v; v.u = p; return v.f; }
static unsigned long long fxbQQ (QQtype x) { union fxuQQ v; v.u = 0; v.f = x; return v.u; }
union fxuSA { SAtype f; unsigned long long u; };
static SAtype fxmSA (unsigned long long p) { union fxuSA v; v.u = p; return v.f; }
static unsigned long long fxbSA (SAtype x) { union fxuSA v; v.u = 0; v.f = x; return v.u; }
union fxuSQ { SQtype f; unsigned long long u; };
static SQtype fxmSQ (unsigned long long p) { union fxuSQ v; v.u = p; return v.f; }
static unsigned long long fxbSQ (SQtype x) { union fxuSQ v; v.u = 0; v.f = x; return v.u; }
union fxuUDA { UDAtype f; unsigned long long u; };
static UDAtype fxmUDA (unsigned long long p) { union fxuUDA v; v.u = p; return v.f; }
static unsigned long long fxbUDA (UDAtype x) { union fxuUDA v; v.u = 0; v.f = x; return v.u; }
union fxuUDQ { UDQtype f; unsigned long long u; };
static UDQtype fxmUDQ (unsigned long long p) { union fxuUDQ v; v.u = p; return v.f; }
static unsigned long long fxbUDQ (UDQtype x) { union fxuUDQ v; v.u = 0; v.f = x; return v.u; }
union fxuUHA { UHAtype f; unsigned long long u; };
static UHAtype fxmUHA (unsigned long long p) { union fxuUHA v; v.u = p; return v.f; }
static unsigned long long fxbUHA (UHAtype x) { union fxuUHA v; v.u = 0; v.f = x; return v.u; }
union fxuUHQ { UHQtype f; unsigned long long u; };
static UHQtype fxmUHQ (unsigned long long p) { union fxuUHQ v; v.u = p; return v.f; }
static unsigned long long fxbUHQ (UHQtype x) { union fxuUHQ v; v.u = 0; v.f = x; return v.u; }
union fxuUQQ { UQQtype f; unsigned long long u; };
static UQQtype fxmUQQ (unsigned long long p) { union fxuUQQ v; v.u = p; return v.f; }
static unsigned long long fxbUQQ (UQQtype x) { union fxuUQQ v; v.u = 0; v.f = x; return v.u; }
union fxuUSA { USAtype f; unsigned long long u; };
static USAtype fxmUSA (unsigned long long p) { union fxuUSA v; v.u = p; return v.f; }
static unsigned long long fxbUSA (USAtype x) { union fxuUSA v; v.u = 0; v.f = x; return v.u; }
union fxuUSQ { USQtype f; unsigned long long u; };
static USQtype fxmUSQ (unsigned long long p) { union fxuUSQ v; v.u = p; return v.f; }
static unsigned long long fxbUSQ (USQtype x) { union fxuUSQ v; v.u = 0; v.f = x; return v.u; }
extern DAtype __gnu_addda3 (DAtype, DAtype);
extern DQtype __gnu_adddq3 (DQtype, DQtype);
extern HAtype __gnu_addha3 (HAtype, HAtype);
extern HQtype __gnu_addhq3 (HQtype, HQtype);
extern QQtype __gnu_addqq3 (QQtype, QQtype);
extern SAtype __gnu_addsa3 (SAtype, SAtype);
extern SQtype __gnu_addsq3 (SQtype, SQtype);
extern UDAtype __gnu_adduda3 (UDAtype, UDAtype);
extern UDQtype __gnu_addudq3 (UDQtype, UDQtype);
extern UHAtype __gnu_adduha3 (UHAtype, UHAtype);
extern UHQtype __gnu_adduhq3 (UHQtype, UHQtype);
extern UQQtype __gnu_adduqq3 (UQQtype, UQQtype);
extern USAtype __gnu_addusa3 (USAtype, USAtype);
extern USQtype __gnu_addusq3 (USQtype, USQtype);
extern DAtype __gnu_ashlda3 (DAtype, word_type);
extern DQtype __gnu_ashldq3 (DQtype, word_type);
extern HAtype __gnu_ashlha3 (HAtype, word_type);
extern DAtype __gnu_ashlhelperda (DAtype, word_type, word_type);
extern DQtype __gnu_ashlhelperdq (DQtype, word_type, word_type);
extern HAtype __gnu_ashlhelperha (HAtype, word_type, word_type);
extern HQtype __gnu_ashlhelperhq (HQtype, word_type, word_type);
extern QQtype __gnu_ashlhelperqq (QQtype, word_type, word_type);
extern SAtype __gnu_ashlhelpersa (SAtype, word_type, word_type);
extern SQtype __gnu_ashlhelpersq (SQtype, word_type, word_type);
extern UDAtype __gnu_ashlhelperuda (UDAtype, word_type, word_type);
extern UDQtype __gnu_ashlhelperudq (UDQtype, word_type, word_type);
extern UHAtype __gnu_ashlhelperuha (UHAtype, word_type, word_type);
extern UHQtype __gnu_ashlhelperuhq (UHQtype, word_type, word_type);
extern UQQtype __gnu_ashlhelperuqq (UQQtype, word_type, word_type);
extern USAtype __gnu_ashlhelperusa (USAtype, word_type, word_type);
extern USQtype __gnu_ashlhelperusq (USQtype, word_type, word_type);
extern HQtype __gnu_ashlhq3 (HQtype, word_type);
extern QQtype __gnu_ashlqq3 (QQtype, word_type);
extern SAtype __gnu_ashlsa3 (SAtype, word_type);
extern SQtype __gnu_ashlsq3 (SQtype, word_type);
extern UDAtype __gnu_ashluda3 (UDAtype, word_type);
extern UDQtype __gnu_ashludq3 (UDQtype, word_type);
extern UHAtype __gnu_ashluha3 (UHAtype, word_type);
extern UHQtype __gnu_ashluhq3 (UHQtype, word_type);
extern UQQtype __gnu_ashluqq3 (UQQtype, word_type);
extern USAtype __gnu_ashlusa3 (USAtype, word_type);
extern USQtype __gnu_ashlusq3 (USQtype, word_type);
extern DAtype __gnu_ashrda3 (DAtype, word_type);
extern DQtype __gnu_ashrdq3 (DQtype, word_type);
extern HAtype __gnu_ashrha3 (HAtype, word_type);
extern HQtype __gnu_ashrhq3 (HQtype, word_type);
extern QQtype __gnu_ashrqq3 (QQtype, word_type);
extern SAtype __gnu_ashrsa3 (SAtype, word_type);
extern SQtype __gnu_ashrsq3 (SQtype, word_type);
extern word_type __gnu_cmpda2 (DAtype, DAtype);
extern word_type __gnu_cmpdq2 (DQtype, DQtype);
extern word_type __gnu_cmpha2 (HAtype, HAtype);
extern word_type __gnu_cmphq2 (HQtype, HQtype);
extern word_type __gnu_cmpqq2 (QQtype, QQtype);
extern word_type __gnu_cmpsa2 (SAtype, SAtype);
extern word_type __gnu_cmpsq2 (SQtype, SQtype);
extern word_type __gnu_cmpuda2 (UDAtype, UDAtype);
extern word_type __gnu_cmpudq2 (UDQtype, UDQtype);
extern word_type __gnu_cmpuha2 (UHAtype, UHAtype);
extern word_type __gnu_cmpuhq2 (UHQtype, UHQtype);
extern word_type __gnu_cmpuqq2 (UQQtype, UQQtype);
extern word_type __gnu_cmpusa2 (USAtype, USAtype);
extern word_type __gnu_cmpusq2 (USQtype, USQtype);
extern DAtype __gnu_divda3 (DAtype, DAtype);
extern DQtype __gnu_divdq3 (DQtype, DQtype);
extern HAtype __gnu_divha3 (HAtype, HAtype);
extern DAtype __gnu_divhelperda (DAtype, DAtype, word_type);
extern DQtype __gnu_divhelperdq (DQtype, DQtype, word_type);
extern HAtype __gnu_divhelperha (HAtype, HAtype, word_type);
extern HQtype __gnu_divhelperhq (HQtype, HQtype, word_type);
extern QQtype __gnu_divhelperqq (QQtype, QQtype, word_type);
extern SAtype __gnu_divhelpersa (SAtype, SAtype, word_type);
extern SQtype __gnu_divhelpersq (SQtype, SQtype, word_type);
extern UDAtype __gnu_divhelperuda (UDAtype, UDAtype, word_type);
extern UDQtype __gnu_divhelperudq (UDQtype, UDQtype, word_type);
extern UHAtype __gnu_divhelperuha (UHAtype, UHAtype, word_type);
extern UHQtype __gnu_divhelperuhq (UHQtype, UHQtype, word_type);
extern UQQtype __gnu_divhelperuqq (UQQtype, UQQtype, word_type);
extern USAtype __gnu_divhelperusa (USAtype, USAtype, word_type);
extern USQtype __gnu_divhelperusq (USQtype, USQtype, word_type);
extern HQtype __gnu_divhq3 (HQtype, HQtype);
extern QQtype __gnu_divqq3 (QQtype, QQtype);
extern SAtype __gnu_divsa3 (SAtype, SAtype);
extern SQtype __gnu_divsq3 (SQtype, SQtype);
extern DFtype __gnu_fractdadf (DAtype);
extern DItype __gnu_fractdadi (DAtype);
extern DQtype __gnu_fractdadq (DAtype);
extern HAtype __gnu_fractdaha2 (DAtype);
extern HItype __gnu_fractdahi (DAtype);
extern HQtype __gnu_fractdahq (DAtype);
extern QItype __gnu_fractdaqi (DAtype);
extern QQtype __gnu_fractdaqq (DAtype);
extern SAtype __gnu_fractdasa2 (DAtype);
extern SFtype __gnu_fractdasf (DAtype);
extern SItype __gnu_fractdasi (DAtype);
extern SQtype __gnu_fractdasq (DAtype);
extern UDAtype __gnu_fractdauda (DAtype);
extern UDQtype __gnu_fractdaudq (DAtype);
extern UHAtype __gnu_fractdauha (DAtype);
extern UHQtype __gnu_fractdauhq (DAtype);
extern UQQtype __gnu_fractdauqq (DAtype);
extern USAtype __gnu_fractdausa (DAtype);
extern USQtype __gnu_fractdausq (DAtype);
extern DAtype __gnu_fractdfda (DFtype);
extern DQtype __gnu_fractdfdq (DFtype);
extern HAtype __gnu_fractdfha (DFtype);
extern HQtype __gnu_fractdfhq (DFtype);
extern QQtype __gnu_fractdfqq (DFtype);
extern SAtype __gnu_fractdfsa (DFtype);
extern SQtype __gnu_fractdfsq (DFtype);
extern UDAtype __gnu_fractdfuda (DFtype);
extern UDQtype __gnu_fractdfudq (DFtype);
extern UHAtype __gnu_fractdfuha (DFtype);
extern UHQtype __gnu_fractdfuhq (DFtype);
extern UQQtype __gnu_fractdfuqq (DFtype);
extern USAtype __gnu_fractdfusa (DFtype);
extern USQtype __gnu_fractdfusq (DFtype);
extern DAtype __gnu_fractdida (DItype);
extern DQtype __gnu_fractdidq (DItype);
extern HAtype __gnu_fractdiha (DItype);
extern HQtype __gnu_fractdihq (DItype);
extern QQtype __gnu_fractdiqq (DItype);
extern SAtype __gnu_fractdisa (DItype);
extern SQtype __gnu_fractdisq (DItype);
extern UDAtype __gnu_fractdiuda (DItype);
extern UDQtype __gnu_fractdiudq (DItype);
extern UHAtype __gnu_fractdiuha (DItype);
extern UHQtype __gnu_fractdiuhq (DItype);
extern UQQtype __gnu_fractdiuqq (DItype);
extern USAtype __gnu_fractdiusa (DItype);
extern USQtype __gnu_fractdiusq (DItype);
extern DAtype __gnu_fractdqda (DQtype);
extern DFtype __gnu_fractdqdf (DQtype);
extern DItype __gnu_fractdqdi (DQtype);
extern HAtype __gnu_fractdqha (DQtype);
extern HItype __gnu_fractdqhi (DQtype);
extern HQtype __gnu_fractdqhq2 (DQtype);
extern QItype __gnu_fractdqqi (DQtype);
extern QQtype __gnu_fractdqqq2 (DQtype);
extern SAtype __gnu_fractdqsa (DQtype);
extern SFtype __gnu_fractdqsf (DQtype);
extern SItype __gnu_fractdqsi (DQtype);
extern SQtype __gnu_fractdqsq2 (DQtype);
extern UDAtype __gnu_fractdquda (DQtype);
extern UDQtype __gnu_fractdqudq (DQtype);
extern UHAtype __gnu_fractdquha (DQtype);
extern UHQtype __gnu_fractdquhq (DQtype);
extern UQQtype __gnu_fractdquqq (DQtype);
extern USAtype __gnu_fractdqusa (DQtype);
extern USQtype __gnu_fractdqusq (DQtype);
extern DAtype __gnu_fracthada2 (HAtype);
extern DFtype __gnu_fracthadf (HAtype);
extern DItype __gnu_fracthadi (HAtype);
extern DQtype __gnu_fracthadq (HAtype);
extern HItype __gnu_fracthahi (HAtype);
extern HQtype __gnu_fracthahq (HAtype);
extern QItype __gnu_fracthaqi (HAtype);
extern QQtype __gnu_fracthaqq (HAtype);
extern SAtype __gnu_fracthasa2 (HAtype);
extern SFtype __gnu_fracthasf (HAtype);
extern SItype __gnu_fracthasi (HAtype);
extern SQtype __gnu_fracthasq (HAtype);
extern UDAtype __gnu_fracthauda (HAtype);
extern UDQtype __gnu_fracthaudq (HAtype);
extern UHAtype __gnu_fracthauha (HAtype);
extern UHQtype __gnu_fracthauhq (HAtype);
extern UQQtype __gnu_fracthauqq (HAtype);
extern USAtype __gnu_fracthausa (HAtype);
extern USQtype __gnu_fracthausq (HAtype);
extern DAtype __gnu_fracthida (HItype);
extern DQtype __gnu_fracthidq (HItype);
extern HAtype __gnu_fracthiha (HItype);
extern HQtype __gnu_fracthihq (HItype);
extern QQtype __gnu_fracthiqq (HItype);
extern SAtype __gnu_fracthisa (HItype);
extern SQtype __gnu_fracthisq (HItype);
extern UDAtype __gnu_fracthiuda (HItype);
extern UDQtype __gnu_fracthiudq (HItype);
extern UHAtype __gnu_fracthiuha (HItype);
extern UHQtype __gnu_fracthiuhq (HItype);
extern UQQtype __gnu_fracthiuqq (HItype);
extern USAtype __gnu_fracthiusa (HItype);
extern USQtype __gnu_fracthiusq (HItype);
extern DAtype __gnu_fracthqda (HQtype);
extern DFtype __gnu_fracthqdf (HQtype);
extern DItype __gnu_fracthqdi (HQtype);
extern DQtype __gnu_fracthqdq2 (HQtype);
extern HAtype __gnu_fracthqha (HQtype);
extern HItype __gnu_fracthqhi (HQtype);
extern QItype __gnu_fracthqqi (HQtype);
extern QQtype __gnu_fracthqqq2 (HQtype);
extern SAtype __gnu_fracthqsa (HQtype);
extern SFtype __gnu_fracthqsf (HQtype);
extern SItype __gnu_fracthqsi (HQtype);
extern SQtype __gnu_fracthqsq2 (HQtype);
extern UDAtype __gnu_fracthquda (HQtype);
extern UDQtype __gnu_fracthqudq (HQtype);
extern UHAtype __gnu_fracthquha (HQtype);
extern UHQtype __gnu_fracthquhq (HQtype);
extern UQQtype __gnu_fracthquqq (HQtype);
extern USAtype __gnu_fracthqusa (HQtype);
extern USQtype __gnu_fracthqusq (HQtype);
extern DAtype __gnu_fractqida (QItype);
extern DQtype __gnu_fractqidq (QItype);
extern HAtype __gnu_fractqiha (QItype);
extern HQtype __gnu_fractqihq (QItype);
extern QQtype __gnu_fractqiqq (QItype);
extern SAtype __gnu_fractqisa (QItype);
extern SQtype __gnu_fractqisq (QItype);
extern UDAtype __gnu_fractqiuda (QItype);
extern UDQtype __gnu_fractqiudq (QItype);
extern UHAtype __gnu_fractqiuha (QItype);
extern UHQtype __gnu_fractqiuhq (QItype);
extern UQQtype __gnu_fractqiuqq (QItype);
extern USAtype __gnu_fractqiusa (QItype);
extern USQtype __gnu_fractqiusq (QItype);
extern DAtype __gnu_fractqqda (QQtype);
extern DFtype __gnu_fractqqdf (QQtype);
extern DItype __gnu_fractqqdi (QQtype);
extern DQtype __gnu_fractqqdq2 (QQtype);
extern HAtype __gnu_fractqqha (QQtype);
extern HItype __gnu_fractqqhi (QQtype);
extern HQtype __gnu_fractqqhq2 (QQtype);
extern QItype __gnu_fractqqqi (QQtype);
extern SAtype __gnu_fractqqsa (QQtype);
extern SFtype __gnu_fractqqsf (QQtype);
extern SItype __gnu_fractqqsi (QQtype);
extern SQtype __gnu_fractqqsq2 (QQtype);
extern UDAtype __gnu_fractqquda (QQtype);
extern UDQtype __gnu_fractqqudq (QQtype);
extern UHAtype __gnu_fractqquha (QQtype);
extern UHQtype __gnu_fractqquhq (QQtype);
extern UQQtype __gnu_fractqquqq (QQtype);
extern USAtype __gnu_fractqqusa (QQtype);
extern USQtype __gnu_fractqqusq (QQtype);
extern DAtype __gnu_fractsada2 (SAtype);
extern DFtype __gnu_fractsadf (SAtype);
extern DItype __gnu_fractsadi (SAtype);
extern DQtype __gnu_fractsadq (SAtype);
extern HAtype __gnu_fractsaha2 (SAtype);
extern HItype __gnu_fractsahi (SAtype);
extern HQtype __gnu_fractsahq (SAtype);
extern QItype __gnu_fractsaqi (SAtype);
extern QQtype __gnu_fractsaqq (SAtype);
extern SFtype __gnu_fractsasf (SAtype);
extern SItype __gnu_fractsasi (SAtype);
extern SQtype __gnu_fractsasq (SAtype);
extern UDAtype __gnu_fractsauda (SAtype);
extern UDQtype __gnu_fractsaudq (SAtype);
extern UHAtype __gnu_fractsauha (SAtype);
extern UHQtype __gnu_fractsauhq (SAtype);
extern UQQtype __gnu_fractsauqq (SAtype);
extern USAtype __gnu_fractsausa (SAtype);
extern USQtype __gnu_fractsausq (SAtype);
extern DAtype __gnu_fractsfda (SFtype);
extern DQtype __gnu_fractsfdq (SFtype);
extern HAtype __gnu_fractsfha (SFtype);
extern HQtype __gnu_fractsfhq (SFtype);
extern QQtype __gnu_fractsfqq (SFtype);
extern SAtype __gnu_fractsfsa (SFtype);
extern SQtype __gnu_fractsfsq (SFtype);
extern UDAtype __gnu_fractsfuda (SFtype);
extern UDQtype __gnu_fractsfudq (SFtype);
extern UHAtype __gnu_fractsfuha (SFtype);
extern UHQtype __gnu_fractsfuhq (SFtype);
extern UQQtype __gnu_fractsfuqq (SFtype);
extern USAtype __gnu_fractsfusa (SFtype);
extern USQtype __gnu_fractsfusq (SFtype);
extern DAtype __gnu_fractsida (SItype);
extern DQtype __gnu_fractsidq (SItype);
extern HAtype __gnu_fractsiha (SItype);
extern HQtype __gnu_fractsihq (SItype);
extern QQtype __gnu_fractsiqq (SItype);
extern SAtype __gnu_fractsisa (SItype);
extern SQtype __gnu_fractsisq (SItype);
extern UDAtype __gnu_fractsiuda (SItype);
extern UDQtype __gnu_fractsiudq (SItype);
extern UHAtype __gnu_fractsiuha (SItype);
extern UHQtype __gnu_fractsiuhq (SItype);
extern UQQtype __gnu_fractsiuqq (SItype);
extern USAtype __gnu_fractsiusa (SItype);
extern USQtype __gnu_fractsiusq (SItype);
extern DAtype __gnu_fractsqda (SQtype);
extern DFtype __gnu_fractsqdf (SQtype);
extern DItype __gnu_fractsqdi (SQtype);
extern DQtype __gnu_fractsqdq2 (SQtype);
extern HAtype __gnu_fractsqha (SQtype);
extern HItype __gnu_fractsqhi (SQtype);
extern HQtype __gnu_fractsqhq2 (SQtype);
extern QItype __gnu_fractsqqi (SQtype);
extern QQtype __gnu_fractsqqq2 (SQtype);
extern SAtype __gnu_fractsqsa (SQtype);
extern SFtype __gnu_fractsqsf (SQtype);
extern SItype __gnu_fractsqsi (SQtype);
extern UDAtype __gnu_fractsquda (SQtype);
extern UDQtype __gnu_fractsqudq (SQtype);
extern UHAtype __gnu_fractsquha (SQtype);
extern UHQtype __gnu_fractsquhq (SQtype);
extern UQQtype __gnu_fractsquqq (SQtype);
extern USAtype __gnu_fractsqusa (SQtype);
extern USQtype __gnu_fractsqusq (SQtype);
extern DAtype __gnu_fractudada (UDAtype);
extern DFtype __gnu_fractudadf (UDAtype);
extern DItype __gnu_fractudadi (UDAtype);
extern DQtype __gnu_fractudadq (UDAtype);
extern HAtype __gnu_fractudaha (UDAtype);
extern HItype __gnu_fractudahi (UDAtype);
extern HQtype __gnu_fractudahq (UDAtype);
extern QItype __gnu_fractudaqi (UDAtype);
extern QQtype __gnu_fractudaqq (UDAtype);
extern SAtype __gnu_fractudasa (UDAtype);
extern SFtype __gnu_fractudasf (UDAtype);
extern SItype __gnu_fractudasi (UDAtype);
extern SQtype __gnu_fractudasq (UDAtype);
extern UDQtype __gnu_fractudaudq (UDAtype);
extern UHAtype __gnu_fractudauha2 (UDAtype);
extern UHQtype __gnu_fractudauhq (UDAtype);
extern UQQtype __gnu_fractudauqq (UDAtype);
extern USAtype __gnu_fractudausa2 (UDAtype);
extern USQtype __gnu_fractudausq (UDAtype);
extern DAtype __gnu_fractudqda (UDQtype);
extern DFtype __gnu_fractudqdf (UDQtype);
extern DItype __gnu_fractudqdi (UDQtype);
extern DQtype __gnu_fractudqdq (UDQtype);
extern HAtype __gnu_fractudqha (UDQtype);
extern HItype __gnu_fractudqhi (UDQtype);
extern HQtype __gnu_fractudqhq (UDQtype);
extern QItype __gnu_fractudqqi (UDQtype);
extern QQtype __gnu_fractudqqq (UDQtype);
extern SAtype __gnu_fractudqsa (UDQtype);
extern SFtype __gnu_fractudqsf (UDQtype);
extern SItype __gnu_fractudqsi (UDQtype);
extern SQtype __gnu_fractudqsq (UDQtype);
extern UDAtype __gnu_fractudquda (UDQtype);
extern UHAtype __gnu_fractudquha (UDQtype);
extern UHQtype __gnu_fractudquhq2 (UDQtype);
extern UQQtype __gnu_fractudquqq2 (UDQtype);
extern USAtype __gnu_fractudqusa (UDQtype);
extern USQtype __gnu_fractudqusq2 (UDQtype);
extern DAtype __gnu_fractuhada (UHAtype);
extern DFtype __gnu_fractuhadf (UHAtype);
extern DItype __gnu_fractuhadi (UHAtype);
extern DQtype __gnu_fractuhadq (UHAtype);
extern HAtype __gnu_fractuhaha (UHAtype);
extern HItype __gnu_fractuhahi (UHAtype);
extern HQtype __gnu_fractuhahq (UHAtype);
extern QItype __gnu_fractuhaqi (UHAtype);
extern QQtype __gnu_fractuhaqq (UHAtype);
extern SAtype __gnu_fractuhasa (UHAtype);
extern SFtype __gnu_fractuhasf (UHAtype);
extern SItype __gnu_fractuhasi (UHAtype);
extern SQtype __gnu_fractuhasq (UHAtype);
extern UDAtype __gnu_fractuhauda2 (UHAtype);
extern UDQtype __gnu_fractuhaudq (UHAtype);
extern UHQtype __gnu_fractuhauhq (UHAtype);
extern UQQtype __gnu_fractuhauqq (UHAtype);
extern USAtype __gnu_fractuhausa2 (UHAtype);
extern USQtype __gnu_fractuhausq (UHAtype);
extern DAtype __gnu_fractuhqda (UHQtype);
extern DFtype __gnu_fractuhqdf (UHQtype);
extern DItype __gnu_fractuhqdi (UHQtype);
extern DQtype __gnu_fractuhqdq (UHQtype);
extern HAtype __gnu_fractuhqha (UHQtype);
extern HItype __gnu_fractuhqhi (UHQtype);
extern HQtype __gnu_fractuhqhq (UHQtype);
extern QItype __gnu_fractuhqqi (UHQtype);
extern QQtype __gnu_fractuhqqq (UHQtype);
extern SAtype __gnu_fractuhqsa (UHQtype);
extern SFtype __gnu_fractuhqsf (UHQtype);
extern SItype __gnu_fractuhqsi (UHQtype);
extern SQtype __gnu_fractuhqsq (UHQtype);
extern UDAtype __gnu_fractuhquda (UHQtype);
extern UDQtype __gnu_fractuhqudq2 (UHQtype);
extern UHAtype __gnu_fractuhquha (UHQtype);
extern UQQtype __gnu_fractuhquqq2 (UHQtype);
extern USAtype __gnu_fractuhqusa (UHQtype);
extern USQtype __gnu_fractuhqusq2 (UHQtype);
extern UDItype __gnu_fractunsdadi (DAtype);
extern UHItype __gnu_fractunsdahi (DAtype);
extern UQItype __gnu_fractunsdaqi (DAtype);
extern USItype __gnu_fractunsdasi (DAtype);
extern DAtype __gnu_fractunsdida (UDItype);
extern DQtype __gnu_fractunsdidq (UDItype);
extern HAtype __gnu_fractunsdiha (UDItype);
extern HQtype __gnu_fractunsdihq (UDItype);
extern QQtype __gnu_fractunsdiqq (UDItype);
extern SAtype __gnu_fractunsdisa (UDItype);
extern SQtype __gnu_fractunsdisq (UDItype);
extern UDAtype __gnu_fractunsdiuda (UDItype);
extern UDQtype __gnu_fractunsdiudq (UDItype);
extern UHAtype __gnu_fractunsdiuha (UDItype);
extern UHQtype __gnu_fractunsdiuhq (UDItype);
extern UQQtype __gnu_fractunsdiuqq (UDItype);
extern USAtype __gnu_fractunsdiusa (UDItype);
extern USQtype __gnu_fractunsdiusq (UDItype);
extern UDItype __gnu_fractunsdqdi (DQtype);
extern UHItype __gnu_fractunsdqhi (DQtype);
extern UQItype __gnu_fractunsdqqi (DQtype);
extern USItype __gnu_fractunsdqsi (DQtype);
extern UDItype __gnu_fractunshadi (HAtype);
extern UHItype __gnu_fractunshahi (HAtype);
extern UQItype __gnu_fractunshaqi (HAtype);
extern USItype __gnu_fractunshasi (HAtype);
extern DAtype __gnu_fractunshida (UHItype);
extern DQtype __gnu_fractunshidq (UHItype);
extern HAtype __gnu_fractunshiha (UHItype);
extern HQtype __gnu_fractunshihq (UHItype);
extern QQtype __gnu_fractunshiqq (UHItype);
extern SAtype __gnu_fractunshisa (UHItype);
extern SQtype __gnu_fractunshisq (UHItype);
extern UDAtype __gnu_fractunshiuda (UHItype);
extern UDQtype __gnu_fractunshiudq (UHItype);
extern UHAtype __gnu_fractunshiuha (UHItype);
extern UHQtype __gnu_fractunshiuhq (UHItype);
extern UQQtype __gnu_fractunshiuqq (UHItype);
extern USAtype __gnu_fractunshiusa (UHItype);
extern USQtype __gnu_fractunshiusq (UHItype);
extern UDItype __gnu_fractunshqdi (HQtype);
extern UHItype __gnu_fractunshqhi (HQtype);
extern UQItype __gnu_fractunshqqi (HQtype);
extern USItype __gnu_fractunshqsi (HQtype);
extern DAtype __gnu_fractunsqida (QItype);
extern DQtype __gnu_fractunsqidq (QItype);
extern HAtype __gnu_fractunsqiha (QItype);
extern HQtype __gnu_fractunsqihq (QItype);
extern QQtype __gnu_fractunsqiqq (QItype);
extern SAtype __gnu_fractunsqisa (QItype);
extern SQtype __gnu_fractunsqisq (QItype);
extern UDAtype __gnu_fractunsqiuda (QItype);
extern UDQtype __gnu_fractunsqiudq (QItype);
extern UHAtype __gnu_fractunsqiuha (QItype);
extern UHQtype __gnu_fractunsqiuhq (QItype);
extern UQQtype __gnu_fractunsqiuqq (QItype);
extern USAtype __gnu_fractunsqiusa (QItype);
extern USQtype __gnu_fractunsqiusq (QItype);
extern UDItype __gnu_fractunsqqdi (QQtype);
extern UHItype __gnu_fractunsqqhi (QQtype);
extern UQItype __gnu_fractunsqqqi (QQtype);
extern USItype __gnu_fractunsqqsi (QQtype);
extern UDItype __gnu_fractunssadi (SAtype);
extern UHItype __gnu_fractunssahi (SAtype);
extern UQItype __gnu_fractunssaqi (SAtype);
extern USItype __gnu_fractunssasi (SAtype);
extern DAtype __gnu_fractunssida (USItype);
extern DQtype __gnu_fractunssidq (USItype);
extern HAtype __gnu_fractunssiha (USItype);
extern HQtype __gnu_fractunssihq (USItype);
extern QQtype __gnu_fractunssiqq (USItype);
extern SAtype __gnu_fractunssisa (USItype);
extern SQtype __gnu_fractunssisq (USItype);
extern UDAtype __gnu_fractunssiuda (USItype);
extern UDQtype __gnu_fractunssiudq (USItype);
extern UHAtype __gnu_fractunssiuha (USItype);
extern UHQtype __gnu_fractunssiuhq (USItype);
extern UQQtype __gnu_fractunssiuqq (USItype);
extern USAtype __gnu_fractunssiusa (USItype);
extern USQtype __gnu_fractunssiusq (USItype);
extern UDItype __gnu_fractunssqdi (SQtype);
extern UHItype __gnu_fractunssqhi (SQtype);
extern UQItype __gnu_fractunssqqi (SQtype);
extern USItype __gnu_fractunssqsi (SQtype);
extern UDItype __gnu_fractunsudadi (UDAtype);
extern UHItype __gnu_fractunsudahi (UDAtype);
extern UQItype __gnu_fractunsudaqi (UDAtype);
extern USItype __gnu_fractunsudasi (UDAtype);
extern UDItype __gnu_fractunsudqdi (UDQtype);
extern UHItype __gnu_fractunsudqhi (UDQtype);
extern UQItype __gnu_fractunsudqqi (UDQtype);
extern USItype __gnu_fractunsudqsi (UDQtype);
extern UDItype __gnu_fractunsuhadi (UHAtype);
extern UHItype __gnu_fractunsuhahi (UHAtype);
extern UQItype __gnu_fractunsuhaqi (UHAtype);
extern USItype __gnu_fractunsuhasi (UHAtype);
extern UDItype __gnu_fractunsuhqdi (UHQtype);
extern UHItype __gnu_fractunsuhqhi (UHQtype);
extern UQItype __gnu_fractunsuhqqi (UHQtype);
extern USItype __gnu_fractunsuhqsi (UHQtype);
extern UDItype __gnu_fractunsuqqdi (UQQtype);
extern UHItype __gnu_fractunsuqqhi (UQQtype);
extern UQItype __gnu_fractunsuqqqi (UQQtype);
extern USItype __gnu_fractunsuqqsi (UQQtype);
extern UDItype __gnu_fractunsusadi (USAtype);
extern UHItype __gnu_fractunsusahi (USAtype);
extern UQItype __gnu_fractunsusaqi (USAtype);
extern USItype __gnu_fractunsusasi (USAtype);
extern UDItype __gnu_fractunsusqdi (USQtype);
extern UHItype __gnu_fractunsusqhi (USQtype);
extern UQItype __gnu_fractunsusqqi (USQtype);
extern USItype __gnu_fractunsusqsi (USQtype);
extern DAtype __gnu_fractuqqda (UQQtype);
extern DFtype __gnu_fractuqqdf (UQQtype);
extern DItype __gnu_fractuqqdi (UQQtype);
extern DQtype __gnu_fractuqqdq (UQQtype);
extern HAtype __gnu_fractuqqha (UQQtype);
extern HItype __gnu_fractuqqhi (UQQtype);
extern HQtype __gnu_fractuqqhq (UQQtype);
extern QItype __gnu_fractuqqqi (UQQtype);
extern QQtype __gnu_fractuqqqq (UQQtype);
extern SAtype __gnu_fractuqqsa (UQQtype);
extern SFtype __gnu_fractuqqsf (UQQtype);
extern SItype __gnu_fractuqqsi (UQQtype);
extern SQtype __gnu_fractuqqsq (UQQtype);
extern UDAtype __gnu_fractuqquda (UQQtype);
extern UDQtype __gnu_fractuqqudq2 (UQQtype);
extern UHAtype __gnu_fractuqquha (UQQtype);
extern UHQtype __gnu_fractuqquhq2 (UQQtype);
extern USAtype __gnu_fractuqqusa (UQQtype);
extern USQtype __gnu_fractuqqusq2 (UQQtype);
extern DAtype __gnu_fractusada (USAtype);
extern DFtype __gnu_fractusadf (USAtype);
extern DItype __gnu_fractusadi (USAtype);
extern DQtype __gnu_fractusadq (USAtype);
extern HAtype __gnu_fractusaha (USAtype);
extern HItype __gnu_fractusahi (USAtype);
extern HQtype __gnu_fractusahq (USAtype);
extern QItype __gnu_fractusaqi (USAtype);
extern QQtype __gnu_fractusaqq (USAtype);
extern SAtype __gnu_fractusasa (USAtype);
extern SFtype __gnu_fractusasf (USAtype);
extern SItype __gnu_fractusasi (USAtype);
extern SQtype __gnu_fractusasq (USAtype);
extern UDAtype __gnu_fractusauda2 (USAtype);
extern UDQtype __gnu_fractusaudq (USAtype);
extern UHAtype __gnu_fractusauha2 (USAtype);
extern UHQtype __gnu_fractusauhq (USAtype);
extern UQQtype __gnu_fractusauqq (USAtype);
extern USQtype __gnu_fractusausq (USAtype);
extern DAtype __gnu_fractusqda (USQtype);
extern DFtype __gnu_fractusqdf (USQtype);
extern DItype __gnu_fractusqdi (USQtype);
extern DQtype __gnu_fractusqdq (USQtype);
extern HAtype __gnu_fractusqha (USQtype);
extern HItype __gnu_fractusqhi (USQtype);
extern HQtype __gnu_fractusqhq (USQtype);
extern QItype __gnu_fractusqqi (USQtype);
extern QQtype __gnu_fractusqqq (USQtype);
extern SAtype __gnu_fractusqsa (USQtype);
extern SFtype __gnu_fractusqsf (USQtype);
extern SItype __gnu_fractusqsi (USQtype);
extern SQtype __gnu_fractusqsq (USQtype);
extern UDAtype __gnu_fractusquda (USQtype);
extern UDQtype __gnu_fractusqudq2 (USQtype);
extern UHAtype __gnu_fractusquha (USQtype);
extern UHQtype __gnu_fractusquhq2 (USQtype);
extern UQQtype __gnu_fractusquqq2 (USQtype);
extern USAtype __gnu_fractusqusa (USQtype);
extern UDAtype __gnu_lshruda3 (UDAtype, word_type);
extern UDQtype __gnu_lshrudq3 (UDQtype, word_type);
extern UHAtype __gnu_lshruha3 (UHAtype, word_type);
extern UHQtype __gnu_lshruhq3 (UHQtype, word_type);
extern UQQtype __gnu_lshruqq3 (UQQtype, word_type);
extern USAtype __gnu_lshrusa3 (USAtype, word_type);
extern USQtype __gnu_lshrusq3 (USQtype, word_type);
extern DAtype __gnu_mulda3 (DAtype, DAtype);
extern DQtype __gnu_muldq3 (DQtype, DQtype);
extern HAtype __gnu_mulha3 (HAtype, HAtype);
extern DAtype __gnu_mulhelperda (DAtype, DAtype, word_type);
extern DQtype __gnu_mulhelperdq (DQtype, DQtype, word_type);
extern HAtype __gnu_mulhelperha (HAtype, HAtype, word_type);
extern HQtype __gnu_mulhelperhq (HQtype, HQtype, word_type);
extern QQtype __gnu_mulhelperqq (QQtype, QQtype, word_type);
extern SAtype __gnu_mulhelpersa (SAtype, SAtype, word_type);
extern SQtype __gnu_mulhelpersq (SQtype, SQtype, word_type);
extern UDAtype __gnu_mulhelperuda (UDAtype, UDAtype, word_type);
extern UDQtype __gnu_mulhelperudq (UDQtype, UDQtype, word_type);
extern UHAtype __gnu_mulhelperuha (UHAtype, UHAtype, word_type);
extern UHQtype __gnu_mulhelperuhq (UHQtype, UHQtype, word_type);
extern UQQtype __gnu_mulhelperuqq (UQQtype, UQQtype, word_type);
extern USAtype __gnu_mulhelperusa (USAtype, USAtype, word_type);
extern USQtype __gnu_mulhelperusq (USQtype, USQtype, word_type);
extern HQtype __gnu_mulhq3 (HQtype, HQtype);
extern QQtype __gnu_mulqq3 (QQtype, QQtype);
extern SAtype __gnu_mulsa3 (SAtype, SAtype);
extern SQtype __gnu_mulsq3 (SQtype, SQtype);
extern UDAtype __gnu_muluda3 (UDAtype, UDAtype);
extern UDQtype __gnu_muludq3 (UDQtype, UDQtype);
extern UHAtype __gnu_muluha3 (UHAtype, UHAtype);
extern UHQtype __gnu_muluhq3 (UHQtype, UHQtype);
extern UQQtype __gnu_muluqq3 (UQQtype, UQQtype);
extern USAtype __gnu_mulusa3 (USAtype, USAtype);
extern USQtype __gnu_mulusq3 (USQtype, USQtype);
extern DAtype __gnu_negda2 (DAtype);
extern DQtype __gnu_negdq2 (DQtype);
extern HAtype __gnu_negha2 (HAtype);
extern HQtype __gnu_neghq2 (HQtype);
extern QQtype __gnu_negqq2 (QQtype);
extern SAtype __gnu_negsa2 (SAtype);
extern SQtype __gnu_negsq2 (SQtype);
extern UDAtype __gnu_neguda2 (UDAtype);
extern UDQtype __gnu_negudq2 (UDQtype);
extern UHAtype __gnu_neguha2 (UHAtype);
extern UHQtype __gnu_neguhq2 (UHQtype);
extern UQQtype __gnu_neguqq2 (UQQtype);
extern USAtype __gnu_negusa2 (USAtype);
extern USQtype __gnu_negusq2 (USQtype);
extern DQtype __gnu_satfractdadq (DAtype);
extern HAtype __gnu_satfractdaha2 (DAtype);
extern HQtype __gnu_satfractdahq (DAtype);
extern QQtype __gnu_satfractdaqq (DAtype);
extern SAtype __gnu_satfractdasa2 (DAtype);
extern SQtype __gnu_satfractdasq (DAtype);
extern UDAtype __gnu_satfractdauda (DAtype);
extern UDQtype __gnu_satfractdaudq (DAtype);
extern UHAtype __gnu_satfractdauha (DAtype);
extern UHQtype __gnu_satfractdauhq (DAtype);
extern UQQtype __gnu_satfractdauqq (DAtype);
extern USAtype __gnu_satfractdausa (DAtype);
extern USQtype __gnu_satfractdausq (DAtype);
extern DAtype __gnu_satfractdfda (DFtype);
extern DQtype __gnu_satfractdfdq (DFtype);
extern HAtype __gnu_satfractdfha (DFtype);
extern HQtype __gnu_satfractdfhq (DFtype);
extern QQtype __gnu_satfractdfqq (DFtype);
extern SAtype __gnu_satfractdfsa (DFtype);
extern SQtype __gnu_satfractdfsq (DFtype);
extern UDAtype __gnu_satfractdfuda (DFtype);
extern UDQtype __gnu_satfractdfudq (DFtype);
extern UHAtype __gnu_satfractdfuha (DFtype);
extern UHQtype __gnu_satfractdfuhq (DFtype);
extern UQQtype __gnu_satfractdfuqq (DFtype);
extern USAtype __gnu_satfractdfusa (DFtype);
extern USQtype __gnu_satfractdfusq (DFtype);
extern DAtype __gnu_satfractdida (DItype);
extern DQtype __gnu_satfractdidq (DItype);
extern HAtype __gnu_satfractdiha (DItype);
extern HQtype __gnu_satfractdihq (DItype);
extern QQtype __gnu_satfractdiqq (DItype);
extern SAtype __gnu_satfractdisa (DItype);
extern SQtype __gnu_satfractdisq (DItype);
extern UDAtype __gnu_satfractdiuda (DItype);
extern UDQtype __gnu_satfractdiudq (DItype);
extern UHAtype __gnu_satfractdiuha (DItype);
extern UHQtype __gnu_satfractdiuhq (DItype);
extern UQQtype __gnu_satfractdiuqq (DItype);
extern USAtype __gnu_satfractdiusa (DItype);
extern USQtype __gnu_satfractdiusq (DItype);
extern DAtype __gnu_satfractdqda (DQtype);
extern HAtype __gnu_satfractdqha (DQtype);
extern HQtype __gnu_satfractdqhq2 (DQtype);
extern QQtype __gnu_satfractdqqq2 (DQtype);
extern SAtype __gnu_satfractdqsa (DQtype);
extern SQtype __gnu_satfractdqsq2 (DQtype);
extern UDAtype __gnu_satfractdquda (DQtype);
extern UDQtype __gnu_satfractdqudq (DQtype);
extern UHAtype __gnu_satfractdquha (DQtype);
extern UHQtype __gnu_satfractdquhq (DQtype);
extern UQQtype __gnu_satfractdquqq (DQtype);
extern USAtype __gnu_satfractdqusa (DQtype);
extern USQtype __gnu_satfractdqusq (DQtype);
extern DAtype __gnu_satfracthada2 (HAtype);
extern DQtype __gnu_satfracthadq (HAtype);
extern HQtype __gnu_satfracthahq (HAtype);
extern QQtype __gnu_satfracthaqq (HAtype);
extern SAtype __gnu_satfracthasa2 (HAtype);
extern SQtype __gnu_satfracthasq (HAtype);
extern UDAtype __gnu_satfracthauda (HAtype);
extern UDQtype __gnu_satfracthaudq (HAtype);
extern UHAtype __gnu_satfracthauha (HAtype);
extern UHQtype __gnu_satfracthauhq (HAtype);
extern UQQtype __gnu_satfracthauqq (HAtype);
extern USAtype __gnu_satfracthausa (HAtype);
extern USQtype __gnu_satfracthausq (HAtype);
extern DAtype __gnu_satfracthida (HItype);
extern DQtype __gnu_satfracthidq (HItype);
extern HAtype __gnu_satfracthiha (HItype);
extern HQtype __gnu_satfracthihq (HItype);
extern QQtype __gnu_satfracthiqq (HItype);
extern SAtype __gnu_satfracthisa (HItype);
extern SQtype __gnu_satfracthisq (HItype);
extern UDAtype __gnu_satfracthiuda (HItype);
extern UDQtype __gnu_satfracthiudq (HItype);
extern UHAtype __gnu_satfracthiuha (HItype);
extern UHQtype __gnu_satfracthiuhq (HItype);
extern UQQtype __gnu_satfracthiuqq (HItype);
extern USAtype __gnu_satfracthiusa (HItype);
extern USQtype __gnu_satfracthiusq (HItype);
extern DAtype __gnu_satfracthqda (HQtype);
extern DQtype __gnu_satfracthqdq2 (HQtype);
extern HAtype __gnu_satfracthqha (HQtype);
extern QQtype __gnu_satfracthqqq2 (HQtype);
extern SAtype __gnu_satfracthqsa (HQtype);
extern SQtype __gnu_satfracthqsq2 (HQtype);
extern UDAtype __gnu_satfracthquda (HQtype);
extern UDQtype __gnu_satfracthqudq (HQtype);
extern UHAtype __gnu_satfracthquha (HQtype);
extern UHQtype __gnu_satfracthquhq (HQtype);
extern UQQtype __gnu_satfracthquqq (HQtype);
extern USAtype __gnu_satfracthqusa (HQtype);
extern USQtype __gnu_satfracthqusq (HQtype);
extern DAtype __gnu_satfractqida (QItype);
extern DQtype __gnu_satfractqidq (QItype);
extern HAtype __gnu_satfractqiha (QItype);
extern HQtype __gnu_satfractqihq (QItype);
extern QQtype __gnu_satfractqiqq (QItype);
extern SAtype __gnu_satfractqisa (QItype);
extern SQtype __gnu_satfractqisq (QItype);
extern UDAtype __gnu_satfractqiuda (QItype);
extern UDQtype __gnu_satfractqiudq (QItype);
extern UHAtype __gnu_satfractqiuha (QItype);
extern UHQtype __gnu_satfractqiuhq (QItype);
extern UQQtype __gnu_satfractqiuqq (QItype);
extern USAtype __gnu_satfractqiusa (QItype);
extern USQtype __gnu_satfractqiusq (QItype);
extern DAtype __gnu_satfractqqda (QQtype);
extern DQtype __gnu_satfractqqdq2 (QQtype);
extern HAtype __gnu_satfractqqha (QQtype);
extern HQtype __gnu_satfractqqhq2 (QQtype);
extern SAtype __gnu_satfractqqsa (QQtype);
extern SQtype __gnu_satfractqqsq2 (QQtype);
extern UDAtype __gnu_satfractqquda (QQtype);
extern UDQtype __gnu_satfractqqudq (QQtype);
extern UHAtype __gnu_satfractqquha (QQtype);
extern UHQtype __gnu_satfractqquhq (QQtype);
extern UQQtype __gnu_satfractqquqq (QQtype);
extern USAtype __gnu_satfractqqusa (QQtype);
extern USQtype __gnu_satfractqqusq (QQtype);
extern DAtype __gnu_satfractsada2 (SAtype);
extern DQtype __gnu_satfractsadq (SAtype);
extern HAtype __gnu_satfractsaha2 (SAtype);
extern HQtype __gnu_satfractsahq (SAtype);
extern QQtype __gnu_satfractsaqq (SAtype);
extern SQtype __gnu_satfractsasq (SAtype);
extern UDAtype __gnu_satfractsauda (SAtype);
extern UDQtype __gnu_satfractsaudq (SAtype);
extern UHAtype __gnu_satfractsauha (SAtype);
extern UHQtype __gnu_satfractsauhq (SAtype);
extern UQQtype __gnu_satfractsauqq (SAtype);
extern USAtype __gnu_satfractsausa (SAtype);
extern USQtype __gnu_satfractsausq (SAtype);
extern DAtype __gnu_satfractsfda (SFtype);
extern DQtype __gnu_satfractsfdq (SFtype);
extern HAtype __gnu_satfractsfha (SFtype);
extern HQtype __gnu_satfractsfhq (SFtype);
extern QQtype __gnu_satfractsfqq (SFtype);
extern SAtype __gnu_satfractsfsa (SFtype);
extern SQtype __gnu_satfractsfsq (SFtype);
extern UDAtype __gnu_satfractsfuda (SFtype);
extern UDQtype __gnu_satfractsfudq (SFtype);
extern UHAtype __gnu_satfractsfuha (SFtype);
extern UHQtype __gnu_satfractsfuhq (SFtype);
extern UQQtype __gnu_satfractsfuqq (SFtype);
extern USAtype __gnu_satfractsfusa (SFtype);
extern USQtype __gnu_satfractsfusq (SFtype);
extern DAtype __gnu_satfractsida (SItype);
extern DQtype __gnu_satfractsidq (SItype);
extern HAtype __gnu_satfractsiha (SItype);
extern HQtype __gnu_satfractsihq (SItype);
extern QQtype __gnu_satfractsiqq (SItype);
extern SAtype __gnu_satfractsisa (SItype);
extern SQtype __gnu_satfractsisq (SItype);
extern UDAtype __gnu_satfractsiuda (SItype);
extern UDQtype __gnu_satfractsiudq (SItype);
extern UHAtype __gnu_satfractsiuha (SItype);
extern UHQtype __gnu_satfractsiuhq (SItype);
extern UQQtype __gnu_satfractsiuqq (SItype);
extern USAtype __gnu_satfractsiusa (SItype);
extern USQtype __gnu_satfractsiusq (SItype);
extern DAtype __gnu_satfractsqda (SQtype);
extern DQtype __gnu_satfractsqdq2 (SQtype);
extern HAtype __gnu_satfractsqha (SQtype);
extern HQtype __gnu_satfractsqhq2 (SQtype);
extern QQtype __gnu_satfractsqqq2 (SQtype);
extern SAtype __gnu_satfractsqsa (SQtype);
extern UDAtype __gnu_satfractsquda (SQtype);
extern UDQtype __gnu_satfractsqudq (SQtype);
extern UHAtype __gnu_satfractsquha (SQtype);
extern UHQtype __gnu_satfractsquhq (SQtype);
extern UQQtype __gnu_satfractsquqq (SQtype);
extern USAtype __gnu_satfractsqusa (SQtype);
extern USQtype __gnu_satfractsqusq (SQtype);
extern DAtype __gnu_satfractudada (UDAtype);
extern DQtype __gnu_satfractudadq (UDAtype);
extern HAtype __gnu_satfractudaha (UDAtype);
extern HQtype __gnu_satfractudahq (UDAtype);
extern QQtype __gnu_satfractudaqq (UDAtype);
extern SAtype __gnu_satfractudasa (UDAtype);
extern SQtype __gnu_satfractudasq (UDAtype);
extern UDQtype __gnu_satfractudaudq (UDAtype);
extern UHAtype __gnu_satfractudauha2 (UDAtype);
extern UHQtype __gnu_satfractudauhq (UDAtype);
extern UQQtype __gnu_satfractudauqq (UDAtype);
extern USAtype __gnu_satfractudausa2 (UDAtype);
extern USQtype __gnu_satfractudausq (UDAtype);
extern DAtype __gnu_satfractudqda (UDQtype);
extern DQtype __gnu_satfractudqdq (UDQtype);
extern HAtype __gnu_satfractudqha (UDQtype);
extern HQtype __gnu_satfractudqhq (UDQtype);
extern QQtype __gnu_satfractudqqq (UDQtype);
extern SAtype __gnu_satfractudqsa (UDQtype);
extern SQtype __gnu_satfractudqsq (UDQtype);
extern UDAtype __gnu_satfractudquda (UDQtype);
extern UHAtype __gnu_satfractudquha (UDQtype);
extern UHQtype __gnu_satfractudquhq2 (UDQtype);
extern UQQtype __gnu_satfractudquqq2 (UDQtype);
extern USAtype __gnu_satfractudqusa (UDQtype);
extern USQtype __gnu_satfractudqusq2 (UDQtype);
extern DAtype __gnu_satfractuhada (UHAtype);
extern DQtype __gnu_satfractuhadq (UHAtype);
extern HAtype __gnu_satfractuhaha (UHAtype);
extern HQtype __gnu_satfractuhahq (UHAtype);
extern QQtype __gnu_satfractuhaqq (UHAtype);
extern SAtype __gnu_satfractuhasa (UHAtype);
extern SQtype __gnu_satfractuhasq (UHAtype);
extern UDAtype __gnu_satfractuhauda2 (UHAtype);
extern UDQtype __gnu_satfractuhaudq (UHAtype);
extern UHQtype __gnu_satfractuhauhq (UHAtype);
extern UQQtype __gnu_satfractuhauqq (UHAtype);
extern USAtype __gnu_satfractuhausa2 (UHAtype);
extern USQtype __gnu_satfractuhausq (UHAtype);
extern DAtype __gnu_satfractuhqda (UHQtype);
extern DQtype __gnu_satfractuhqdq (UHQtype);
extern HAtype __gnu_satfractuhqha (UHQtype);
extern HQtype __gnu_satfractuhqhq (UHQtype);
extern QQtype __gnu_satfractuhqqq (UHQtype);
extern SAtype __gnu_satfractuhqsa (UHQtype);
extern SQtype __gnu_satfractuhqsq (UHQtype);
extern UDAtype __gnu_satfractuhquda (UHQtype);
extern UDQtype __gnu_satfractuhqudq2 (UHQtype);
extern UHAtype __gnu_satfractuhquha (UHQtype);
extern UQQtype __gnu_satfractuhquqq2 (UHQtype);
extern USAtype __gnu_satfractuhqusa (UHQtype);
extern USQtype __gnu_satfractuhqusq2 (UHQtype);
extern DAtype __gnu_satfractunsdida (UDItype);
extern DQtype __gnu_satfractunsdidq (UDItype);
extern HAtype __gnu_satfractunsdiha (UDItype);
extern HQtype __gnu_satfractunsdihq (UDItype);
extern QQtype __gnu_satfractunsdiqq (UDItype);
extern SAtype __gnu_satfractunsdisa (UDItype);
extern SQtype __gnu_satfractunsdisq (UDItype);
extern UDAtype __gnu_satfractunsdiuda (UDItype);
extern UDQtype __gnu_satfractunsdiudq (UDItype);
extern UHAtype __gnu_satfractunsdiuha (UDItype);
extern UHQtype __gnu_satfractunsdiuhq (UDItype);
extern UQQtype __gnu_satfractunsdiuqq (UDItype);
extern USAtype __gnu_satfractunsdiusa (UDItype);
extern USQtype __gnu_satfractunsdiusq (UDItype);
extern DAtype __gnu_satfractunshida (UHItype);
extern DQtype __gnu_satfractunshidq (UHItype);
extern HAtype __gnu_satfractunshiha (UHItype);
extern HQtype __gnu_satfractunshihq (UHItype);
extern QQtype __gnu_satfractunshiqq (UHItype);
extern SAtype __gnu_satfractunshisa (UHItype);
extern SQtype __gnu_satfractunshisq (UHItype);
extern UDAtype __gnu_satfractunshiuda (UHItype);
extern UDQtype __gnu_satfractunshiudq (UHItype);
extern UHAtype __gnu_satfractunshiuha (UHItype);
extern UHQtype __gnu_satfractunshiuhq (UHItype);
extern UQQtype __gnu_satfractunshiuqq (UHItype);
extern USAtype __gnu_satfractunshiusa (UHItype);
extern USQtype __gnu_satfractunshiusq (UHItype);
extern DAtype __gnu_satfractunsqida (QItype);
extern DQtype __gnu_satfractunsqidq (QItype);
extern HAtype __gnu_satfractunsqiha (QItype);
extern HQtype __gnu_satfractunsqihq (QItype);
extern QQtype __gnu_satfractunsqiqq (QItype);
extern SAtype __gnu_satfractunsqisa (QItype);
extern SQtype __gnu_satfractunsqisq (QItype);
extern UDAtype __gnu_satfractunsqiuda (QItype);
extern UDQtype __gnu_satfractunsqiudq (QItype);
extern UHAtype __gnu_satfractunsqiuha (QItype);
extern UHQtype __gnu_satfractunsqiuhq (QItype);
extern UQQtype __gnu_satfractunsqiuqq (QItype);
extern USAtype __gnu_satfractunsqiusa (QItype);
extern USQtype __gnu_satfractunsqiusq (QItype);
extern DAtype __gnu_satfractunssida (USItype);
extern DQtype __gnu_satfractunssidq (USItype);
extern HAtype __gnu_satfractunssiha (USItype);
extern HQtype __gnu_satfractunssihq (USItype);
extern QQtype __gnu_satfractunssiqq (USItype);
extern SAtype __gnu_satfractunssisa (USItype);
extern SQtype __gnu_satfractunssisq (USItype);
extern UDAtype __gnu_satfractunssiuda (USItype);
extern UDQtype __gnu_satfractunssiudq (USItype);
extern UHAtype __gnu_satfractunssiuha (USItype);
extern UHQtype __gnu_satfractunssiuhq (USItype);
extern UQQtype __gnu_satfractunssiuqq (USItype);
extern USAtype __gnu_satfractunssiusa (USItype);
extern USQtype __gnu_satfractunssiusq (USItype);
extern DAtype __gnu_satfractuqqda (UQQtype);
extern DQtype __gnu_satfractuqqdq (UQQtype);
extern HAtype __gnu_satfractuqqha (UQQtype);
extern HQtype __gnu_satfractuqqhq (UQQtype);
extern QQtype __gnu_satfractuqqqq (UQQtype);
extern SAtype __gnu_satfractuqqsa (UQQtype);
extern SQtype __gnu_satfractuqqsq (UQQtype);
extern UDAtype __gnu_satfractuqquda (UQQtype);
extern UDQtype __gnu_satfractuqqudq2 (UQQtype);
extern UHAtype __gnu_satfractuqquha (UQQtype);
extern UHQtype __gnu_satfractuqquhq2 (UQQtype);
extern USAtype __gnu_satfractuqqusa (UQQtype);
extern USQtype __gnu_satfractuqqusq2 (UQQtype);
extern DAtype __gnu_satfractusada (USAtype);
extern DQtype __gnu_satfractusadq (USAtype);
extern HAtype __gnu_satfractusaha (USAtype);
extern HQtype __gnu_satfractusahq (USAtype);
extern QQtype __gnu_satfractusaqq (USAtype);
extern SAtype __gnu_satfractusasa (USAtype);
extern SQtype __gnu_satfractusasq (USAtype);
extern UDAtype __gnu_satfractusauda2 (USAtype);
extern UDQtype __gnu_satfractusaudq (USAtype);
extern UHAtype __gnu_satfractusauha2 (USAtype);
extern UHQtype __gnu_satfractusauhq (USAtype);
extern UQQtype __gnu_satfractusauqq (USAtype);
extern USQtype __gnu_satfractusausq (USAtype);
extern DAtype __gnu_satfractusqda (USQtype);
extern DQtype __gnu_satfractusqdq (USQtype);
extern HAtype __gnu_satfractusqha (USQtype);
extern HQtype __gnu_satfractusqhq (USQtype);
extern QQtype __gnu_satfractusqqq (USQtype);
extern SAtype __gnu_satfractusqsa (USQtype);
extern SQtype __gnu_satfractusqsq (USQtype);
extern UDAtype __gnu_satfractusquda (USQtype);
extern UDQtype __gnu_satfractusqudq2 (USQtype);
extern UHAtype __gnu_satfractusquha (USQtype);
extern UHQtype __gnu_satfractusquhq2 (USQtype);
extern UQQtype __gnu_satfractusquqq2 (USQtype);
extern USAtype __gnu_satfractusqusa (USQtype);
extern void __gnu_saturate1ha (SItype *);
extern void __gnu_saturate1hq (SItype *);
extern void __gnu_saturate1qq (HItype *);
extern void __gnu_saturate1sa (DItype *);
extern void __gnu_saturate1sq (DItype *);
extern void __gnu_saturate1uha (USItype *);
extern void __gnu_saturate1uhq (USItype *);
extern void __gnu_saturate1uqq (UHItype *);
extern void __gnu_saturate1usa (UDItype *);
extern void __gnu_saturate1usq (UDItype *);
extern void __gnu_saturate2da (DItype *, DItype *);
extern void __gnu_saturate2dq (DItype *, DItype *);
extern void __gnu_saturate2uda (UDItype *, UDItype *);
extern void __gnu_saturate2udq (UDItype *, UDItype *);
extern DAtype __gnu_ssaddda3 (DAtype, DAtype);
extern DQtype __gnu_ssadddq3 (DQtype, DQtype);
extern HAtype __gnu_ssaddha3 (HAtype, HAtype);
extern HQtype __gnu_ssaddhq3 (HQtype, HQtype);
extern QQtype __gnu_ssaddqq3 (QQtype, QQtype);
extern SAtype __gnu_ssaddsa3 (SAtype, SAtype);
extern SQtype __gnu_ssaddsq3 (SQtype, SQtype);
extern DAtype __gnu_ssashlda3 (DAtype, word_type);
extern DQtype __gnu_ssashldq3 (DQtype, word_type);
extern HAtype __gnu_ssashlha3 (HAtype, word_type);
extern HQtype __gnu_ssashlhq3 (HQtype, word_type);
extern QQtype __gnu_ssashlqq3 (QQtype, word_type);
extern SAtype __gnu_ssashlsa3 (SAtype, word_type);
extern SQtype __gnu_ssashlsq3 (SQtype, word_type);
extern DAtype __gnu_ssdivda3 (DAtype, DAtype);
extern DQtype __gnu_ssdivdq3 (DQtype, DQtype);
extern HAtype __gnu_ssdivha3 (HAtype, HAtype);
extern HQtype __gnu_ssdivhq3 (HQtype, HQtype);
extern QQtype __gnu_ssdivqq3 (QQtype, QQtype);
extern SAtype __gnu_ssdivsa3 (SAtype, SAtype);
extern SQtype __gnu_ssdivsq3 (SQtype, SQtype);
extern DAtype __gnu_ssmulda3 (DAtype, DAtype);
extern DQtype __gnu_ssmuldq3 (DQtype, DQtype);
extern HAtype __gnu_ssmulha3 (HAtype, HAtype);
extern HQtype __gnu_ssmulhq3 (HQtype, HQtype);
extern QQtype __gnu_ssmulqq3 (QQtype, QQtype);
extern SAtype __gnu_ssmulsa3 (SAtype, SAtype);
extern SQtype __gnu_ssmulsq3 (SQtype, SQtype);
extern DAtype __gnu_ssnegda2 (DAtype);
extern DQtype __gnu_ssnegdq2 (DQtype);
extern HAtype __gnu_ssnegha2 (HAtype);
extern HQtype __gnu_ssneghq2 (HQtype);
extern QQtype __gnu_ssnegqq2 (QQtype);
extern SAtype __gnu_ssnegsa2 (SAtype);
extern SQtype __gnu_ssnegsq2 (SQtype);
extern DAtype __gnu_sssubda3 (DAtype, DAtype);
extern DQtype __gnu_sssubdq3 (DQtype, DQtype);
extern HAtype __gnu_sssubha3 (HAtype, HAtype);
extern HQtype __gnu_sssubhq3 (HQtype, HQtype);
extern QQtype __gnu_sssubqq3 (QQtype, QQtype);
extern SAtype __gnu_sssubsa3 (SAtype, SAtype);
extern SQtype __gnu_sssubsq3 (SQtype, SQtype);
extern DAtype __gnu_subda3 (DAtype, DAtype);
extern DQtype __gnu_subdq3 (DQtype, DQtype);
extern HAtype __gnu_subha3 (HAtype, HAtype);
extern HQtype __gnu_subhq3 (HQtype, HQtype);
extern QQtype __gnu_subqq3 (QQtype, QQtype);
extern SAtype __gnu_subsa3 (SAtype, SAtype);
extern SQtype __gnu_subsq3 (SQtype, SQtype);
extern UDAtype __gnu_subuda3 (UDAtype, UDAtype);
extern UDQtype __gnu_subudq3 (UDQtype, UDQtype);
extern UHAtype __gnu_subuha3 (UHAtype, UHAtype);
extern UHQtype __gnu_subuhq3 (UHQtype, UHQtype);
extern UQQtype __gnu_subuqq3 (UQQtype, UQQtype);
extern USAtype __gnu_subusa3 (USAtype, USAtype);
extern USQtype __gnu_subusq3 (USQtype, USQtype);
extern UDAtype __gnu_udivuda3 (UDAtype, UDAtype);
extern UDQtype __gnu_udivudq3 (UDQtype, UDQtype);
extern UHAtype __gnu_udivuha3 (UHAtype, UHAtype);
extern UHQtype __gnu_udivuhq3 (UHQtype, UHQtype);
extern UQQtype __gnu_udivuqq3 (UQQtype, UQQtype);
extern USAtype __gnu_udivusa3 (USAtype, USAtype);
extern USQtype __gnu_udivusq3 (USQtype, USQtype);
extern UDAtype __gnu_usadduda3 (UDAtype, UDAtype);
extern UDQtype __gnu_usaddudq3 (UDQtype, UDQtype);
extern UHAtype __gnu_usadduha3 (UHAtype, UHAtype);
extern UHQtype __gnu_usadduhq3 (UHQtype, UHQtype);
extern UQQtype __gnu_usadduqq3 (UQQtype, UQQtype);
extern USAtype __gnu_usaddusa3 (USAtype, USAtype);
extern USQtype __gnu_usaddusq3 (USQtype, USQtype);
extern UDAtype __gnu_usashluda3 (UDAtype, word_type);
extern UDQtype __gnu_usashludq3 (UDQtype, word_type);
extern UHAtype __gnu_usashluha3 (UHAtype, word_type);
extern UHQtype __gnu_usashluhq3 (UHQtype, word_type);
extern UQQtype __gnu_usashluqq3 (UQQtype, word_type);
extern USAtype __gnu_usashlusa3 (USAtype, word_type);
extern USQtype __gnu_usashlusq3 (USQtype, word_type);
extern UDAtype __gnu_usdivuda3 (UDAtype, UDAtype);
extern UDQtype __gnu_usdivudq3 (UDQtype, UDQtype);
extern UHAtype __gnu_usdivuha3 (UHAtype, UHAtype);
extern UHQtype __gnu_usdivuhq3 (UHQtype, UHQtype);
extern UQQtype __gnu_usdivuqq3 (UQQtype, UQQtype);
extern USAtype __gnu_usdivusa3 (USAtype, USAtype);
extern USQtype __gnu_usdivusq3 (USQtype, USQtype);
extern UDAtype __gnu_usmuluda3 (UDAtype, UDAtype);
extern UDQtype __gnu_usmuludq3 (UDQtype, UDQtype);
extern UHAtype __gnu_usmuluha3 (UHAtype, UHAtype);
extern UHQtype __gnu_usmuluhq3 (UHQtype, UHQtype);
extern UQQtype __gnu_usmuluqq3 (UQQtype, UQQtype);
extern USAtype __gnu_usmulusa3 (USAtype, USAtype);
extern USQtype __gnu_usmulusq3 (USQtype, USQtype);
extern UDAtype __gnu_usneguda2 (UDAtype);
extern UDQtype __gnu_usnegudq2 (UDQtype);
extern UHAtype __gnu_usneguha2 (UHAtype);
extern UHQtype __gnu_usneguhq2 (UHQtype);
extern UQQtype __gnu_usneguqq2 (UQQtype);
extern USAtype __gnu_usnegusa2 (USAtype);
extern USQtype __gnu_usnegusq2 (USQtype);
extern UDAtype __gnu_ussubuda3 (UDAtype, UDAtype);
extern UDQtype __gnu_ussubudq3 (UDQtype, UDQtype);
extern UHAtype __gnu_ussubuha3 (UHAtype, UHAtype);
extern UHQtype __gnu_ussubuhq3 (UHQtype, UHQtype);
extern UQQtype __gnu_ussubuqq3 (UQQtype, UQQtype);
extern USAtype __gnu_ussubusa3 (USAtype, USAtype);
extern USQtype __gnu_ussubusq3 (USQtype, USQtype);
static void fxt0 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbDA (__gnu_addda3 (fxmDA (0x3535353535353535ULL), fxmDA (0x2121212121212121ULL)))); }
  { w (fxbDA (__gnu_addda3 (fxmDA (0x8181818181818181ULL), fxmDA (0x0303030303030303ULL)))); }
  { w (fxbDA (__gnu_addda3 (fxmDA (0x0101010101017f01ULL), fxmDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDQ (__gnu_adddq3 (fxmDQ (0x3535353535353535ULL), fxmDQ (0x2121212121212121ULL)))); }
  { w (fxbDQ (__gnu_adddq3 (fxmDQ (0x8181818181818181ULL), fxmDQ (0x0303030303030303ULL)))); }
  { w (fxbDQ (__gnu_adddq3 (fxmDQ (0x0101010101017f01ULL), fxmDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHA (__gnu_addha3 (fxmHA (0x3535353535353535ULL), fxmHA (0x2121212121212121ULL)))); }
  { w (fxbHA (__gnu_addha3 (fxmHA (0x8181818181818181ULL), fxmHA (0x0303030303030303ULL)))); }
  { w (fxbHA (__gnu_addha3 (fxmHA (0x0101010101017f01ULL), fxmHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHQ (__gnu_addhq3 (fxmHQ (0x3535353535353535ULL), fxmHQ (0x2121212121212121ULL)))); }
  { w (fxbHQ (__gnu_addhq3 (fxmHQ (0x8181818181818181ULL), fxmHQ (0x0303030303030303ULL)))); }
  { w (fxbHQ (__gnu_addhq3 (fxmHQ (0x0101010101017f01ULL), fxmHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbQQ (__gnu_addqq3 (fxmQQ (0x3535353535353535ULL), fxmQQ (0x2121212121212121ULL)))); }
  { w (fxbQQ (__gnu_addqq3 (fxmQQ (0x8181818181818181ULL), fxmQQ (0x0303030303030303ULL)))); }
  { w (fxbQQ (__gnu_addqq3 (fxmQQ (0x0101010101017f01ULL), fxmQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSA (__gnu_addsa3 (fxmSA (0x3535353535353535ULL), fxmSA (0x2121212121212121ULL)))); }
  { w (fxbSA (__gnu_addsa3 (fxmSA (0x8181818181818181ULL), fxmSA (0x0303030303030303ULL)))); }
  { w (fxbSA (__gnu_addsa3 (fxmSA (0x0101010101017f01ULL), fxmSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSQ (__gnu_addsq3 (fxmSQ (0x3535353535353535ULL), fxmSQ (0x2121212121212121ULL)))); }
  { w (fxbSQ (__gnu_addsq3 (fxmSQ (0x8181818181818181ULL), fxmSQ (0x0303030303030303ULL)))); }
  { w (fxbSQ (__gnu_addsq3 (fxmSQ (0x0101010101017f01ULL), fxmSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDA (__gnu_adduda3 (fxmUDA (0x3535353535353535ULL), fxmUDA (0x2121212121212121ULL)))); }
  { w (fxbUDA (__gnu_adduda3 (fxmUDA (0x8181818181818181ULL), fxmUDA (0x0303030303030303ULL)))); }
  { w (fxbUDA (__gnu_adduda3 (fxmUDA (0x0101010101017f01ULL), fxmUDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDQ (__gnu_addudq3 (fxmUDQ (0x3535353535353535ULL), fxmUDQ (0x2121212121212121ULL)))); }
  { w (fxbUDQ (__gnu_addudq3 (fxmUDQ (0x8181818181818181ULL), fxmUDQ (0x0303030303030303ULL)))); }
  { w (fxbUDQ (__gnu_addudq3 (fxmUDQ (0x0101010101017f01ULL), fxmUDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHA (__gnu_adduha3 (fxmUHA (0x3535353535353535ULL), fxmUHA (0x2121212121212121ULL)))); }
  { w (fxbUHA (__gnu_adduha3 (fxmUHA (0x8181818181818181ULL), fxmUHA (0x0303030303030303ULL)))); }
  { w (fxbUHA (__gnu_adduha3 (fxmUHA (0x0101010101017f01ULL), fxmUHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHQ (__gnu_adduhq3 (fxmUHQ (0x3535353535353535ULL), fxmUHQ (0x2121212121212121ULL)))); }
  { w (fxbUHQ (__gnu_adduhq3 (fxmUHQ (0x8181818181818181ULL), fxmUHQ (0x0303030303030303ULL)))); }
  { w (fxbUHQ (__gnu_adduhq3 (fxmUHQ (0x0101010101017f01ULL), fxmUHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUQQ (__gnu_adduqq3 (fxmUQQ (0x3535353535353535ULL), fxmUQQ (0x2121212121212121ULL)))); }
  { w (fxbUQQ (__gnu_adduqq3 (fxmUQQ (0x8181818181818181ULL), fxmUQQ (0x0303030303030303ULL)))); }
  { w (fxbUQQ (__gnu_adduqq3 (fxmUQQ (0x0101010101017f01ULL), fxmUQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSA (__gnu_addusa3 (fxmUSA (0x3535353535353535ULL), fxmUSA (0x2121212121212121ULL)))); }
  { w (fxbUSA (__gnu_addusa3 (fxmUSA (0x8181818181818181ULL), fxmUSA (0x0303030303030303ULL)))); }
  { w (fxbUSA (__gnu_addusa3 (fxmUSA (0x0101010101017f01ULL), fxmUSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSQ (__gnu_addusq3 (fxmUSQ (0x3535353535353535ULL), fxmUSQ (0x2121212121212121ULL)))); }
  { w (fxbUSQ (__gnu_addusq3 (fxmUSQ (0x8181818181818181ULL), fxmUSQ (0x0303030303030303ULL)))); }
  { w (fxbUSQ (__gnu_addusq3 (fxmUSQ (0x0101010101017f01ULL), fxmUSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDA (__gnu_ashlda3 (fxmDA (0x3535353535353535ULL), 1))); }
  { w (fxbDA (__gnu_ashlda3 (fxmDA (0x8181818181818181ULL), 2))); }
  { w (fxbDA (__gnu_ashlda3 (fxmDA (0x0101010101017f01ULL), 3))); }
  { w (fxbDQ (__gnu_ashldq3 (fxmDQ (0x3535353535353535ULL), 1))); }
  { w (fxbDQ (__gnu_ashldq3 (fxmDQ (0x8181818181818181ULL), 2))); }
  { w (fxbDQ (__gnu_ashldq3 (fxmDQ (0x0101010101017f01ULL), 3))); }
  { w (fxbHA (__gnu_ashlha3 (fxmHA (0x3535353535353535ULL), 1))); }
  { w (fxbHA (__gnu_ashlha3 (fxmHA (0x8181818181818181ULL), 2))); }
  { w (fxbHA (__gnu_ashlha3 (fxmHA (0x0101010101017f01ULL), 3))); }
  { w (fxbDA (__gnu_ashlhelperda (fxmDA (0x3535353535353535ULL), 1, 0))); }
  { w (fxbDA (__gnu_ashlhelperda (fxmDA (0x8181818181818181ULL), 2, 1))); }
  { w (fxbDA (__gnu_ashlhelperda (fxmDA (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbDQ (__gnu_ashlhelperdq (fxmDQ (0x3535353535353535ULL), 1, 0))); }
  { w (fxbDQ (__gnu_ashlhelperdq (fxmDQ (0x8181818181818181ULL), 2, 1))); }
  { w (fxbDQ (__gnu_ashlhelperdq (fxmDQ (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbHA (__gnu_ashlhelperha (fxmHA (0x3535353535353535ULL), 1, 0))); }
  { w (fxbHA (__gnu_ashlhelperha (fxmHA (0x8181818181818181ULL), 2, 1))); }
  { w (fxbHA (__gnu_ashlhelperha (fxmHA (0x0101010101017f01ULL), 3, 0))); }
}
static void fxt1 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbHQ (__gnu_ashlhelperhq (fxmHQ (0x3535353535353535ULL), 1, 0))); }
  { w (fxbHQ (__gnu_ashlhelperhq (fxmHQ (0x8181818181818181ULL), 2, 1))); }
  { w (fxbHQ (__gnu_ashlhelperhq (fxmHQ (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbQQ (__gnu_ashlhelperqq (fxmQQ (0x3535353535353535ULL), 1, 0))); }
  { w (fxbQQ (__gnu_ashlhelperqq (fxmQQ (0x8181818181818181ULL), 2, 1))); }
  { w (fxbQQ (__gnu_ashlhelperqq (fxmQQ (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbSA (__gnu_ashlhelpersa (fxmSA (0x3535353535353535ULL), 1, 0))); }
  { w (fxbSA (__gnu_ashlhelpersa (fxmSA (0x8181818181818181ULL), 2, 1))); }
  { w (fxbSA (__gnu_ashlhelpersa (fxmSA (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbSQ (__gnu_ashlhelpersq (fxmSQ (0x3535353535353535ULL), 1, 0))); }
  { w (fxbSQ (__gnu_ashlhelpersq (fxmSQ (0x8181818181818181ULL), 2, 1))); }
  { w (fxbSQ (__gnu_ashlhelpersq (fxmSQ (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbUDA (__gnu_ashlhelperuda (fxmUDA (0x3535353535353535ULL), 1, 0))); }
  { w (fxbUDA (__gnu_ashlhelperuda (fxmUDA (0x8181818181818181ULL), 2, 1))); }
  { w (fxbUDA (__gnu_ashlhelperuda (fxmUDA (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbUDQ (__gnu_ashlhelperudq (fxmUDQ (0x3535353535353535ULL), 1, 0))); }
  { w (fxbUDQ (__gnu_ashlhelperudq (fxmUDQ (0x8181818181818181ULL), 2, 1))); }
  { w (fxbUDQ (__gnu_ashlhelperudq (fxmUDQ (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbUHA (__gnu_ashlhelperuha (fxmUHA (0x3535353535353535ULL), 1, 0))); }
  { w (fxbUHA (__gnu_ashlhelperuha (fxmUHA (0x8181818181818181ULL), 2, 1))); }
  { w (fxbUHA (__gnu_ashlhelperuha (fxmUHA (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbUHQ (__gnu_ashlhelperuhq (fxmUHQ (0x3535353535353535ULL), 1, 0))); }
  { w (fxbUHQ (__gnu_ashlhelperuhq (fxmUHQ (0x8181818181818181ULL), 2, 1))); }
  { w (fxbUHQ (__gnu_ashlhelperuhq (fxmUHQ (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbUQQ (__gnu_ashlhelperuqq (fxmUQQ (0x3535353535353535ULL), 1, 0))); }
  { w (fxbUQQ (__gnu_ashlhelperuqq (fxmUQQ (0x8181818181818181ULL), 2, 1))); }
  { w (fxbUQQ (__gnu_ashlhelperuqq (fxmUQQ (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbUSA (__gnu_ashlhelperusa (fxmUSA (0x3535353535353535ULL), 1, 0))); }
  { w (fxbUSA (__gnu_ashlhelperusa (fxmUSA (0x8181818181818181ULL), 2, 1))); }
  { w (fxbUSA (__gnu_ashlhelperusa (fxmUSA (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbUSQ (__gnu_ashlhelperusq (fxmUSQ (0x3535353535353535ULL), 1, 0))); }
  { w (fxbUSQ (__gnu_ashlhelperusq (fxmUSQ (0x8181818181818181ULL), 2, 1))); }
  { w (fxbUSQ (__gnu_ashlhelperusq (fxmUSQ (0x0101010101017f01ULL), 3, 0))); }
  { w (fxbHQ (__gnu_ashlhq3 (fxmHQ (0x3535353535353535ULL), 1))); }
  { w (fxbHQ (__gnu_ashlhq3 (fxmHQ (0x8181818181818181ULL), 2))); }
  { w (fxbHQ (__gnu_ashlhq3 (fxmHQ (0x0101010101017f01ULL), 3))); }
  { w (fxbQQ (__gnu_ashlqq3 (fxmQQ (0x3535353535353535ULL), 1))); }
  { w (fxbQQ (__gnu_ashlqq3 (fxmQQ (0x8181818181818181ULL), 2))); }
  { w (fxbQQ (__gnu_ashlqq3 (fxmQQ (0x0101010101017f01ULL), 3))); }
  { w (fxbSA (__gnu_ashlsa3 (fxmSA (0x3535353535353535ULL), 1))); }
  { w (fxbSA (__gnu_ashlsa3 (fxmSA (0x8181818181818181ULL), 2))); }
  { w (fxbSA (__gnu_ashlsa3 (fxmSA (0x0101010101017f01ULL), 3))); }
  { w (fxbSQ (__gnu_ashlsq3 (fxmSQ (0x3535353535353535ULL), 1))); }
  { w (fxbSQ (__gnu_ashlsq3 (fxmSQ (0x8181818181818181ULL), 2))); }
  { w (fxbSQ (__gnu_ashlsq3 (fxmSQ (0x0101010101017f01ULL), 3))); }
  { w (fxbUDA (__gnu_ashluda3 (fxmUDA (0x3535353535353535ULL), 1))); }
  { w (fxbUDA (__gnu_ashluda3 (fxmUDA (0x8181818181818181ULL), 2))); }
  { w (fxbUDA (__gnu_ashluda3 (fxmUDA (0x0101010101017f01ULL), 3))); }
  { w (fxbUDQ (__gnu_ashludq3 (fxmUDQ (0x3535353535353535ULL), 1))); }
  { w (fxbUDQ (__gnu_ashludq3 (fxmUDQ (0x8181818181818181ULL), 2))); }
  { w (fxbUDQ (__gnu_ashludq3 (fxmUDQ (0x0101010101017f01ULL), 3))); }
  { w (fxbUHA (__gnu_ashluha3 (fxmUHA (0x3535353535353535ULL), 1))); }
  { w (fxbUHA (__gnu_ashluha3 (fxmUHA (0x8181818181818181ULL), 2))); }
  { w (fxbUHA (__gnu_ashluha3 (fxmUHA (0x0101010101017f01ULL), 3))); }
  { w (fxbUHQ (__gnu_ashluhq3 (fxmUHQ (0x3535353535353535ULL), 1))); }
  { w (fxbUHQ (__gnu_ashluhq3 (fxmUHQ (0x8181818181818181ULL), 2))); }
  { w (fxbUHQ (__gnu_ashluhq3 (fxmUHQ (0x0101010101017f01ULL), 3))); }
  { w (fxbUQQ (__gnu_ashluqq3 (fxmUQQ (0x3535353535353535ULL), 1))); }
  { w (fxbUQQ (__gnu_ashluqq3 (fxmUQQ (0x8181818181818181ULL), 2))); }
  { w (fxbUQQ (__gnu_ashluqq3 (fxmUQQ (0x0101010101017f01ULL), 3))); }
}
static void fxt2 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUSA (__gnu_ashlusa3 (fxmUSA (0x3535353535353535ULL), 1))); }
  { w (fxbUSA (__gnu_ashlusa3 (fxmUSA (0x8181818181818181ULL), 2))); }
  { w (fxbUSA (__gnu_ashlusa3 (fxmUSA (0x0101010101017f01ULL), 3))); }
  { w (fxbUSQ (__gnu_ashlusq3 (fxmUSQ (0x3535353535353535ULL), 1))); }
  { w (fxbUSQ (__gnu_ashlusq3 (fxmUSQ (0x8181818181818181ULL), 2))); }
  { w (fxbUSQ (__gnu_ashlusq3 (fxmUSQ (0x0101010101017f01ULL), 3))); }
  { w (fxbDA (__gnu_ashrda3 (fxmDA (0x3535353535353535ULL), 1))); }
  { w (fxbDA (__gnu_ashrda3 (fxmDA (0x8181818181818181ULL), 2))); }
  { w (fxbDA (__gnu_ashrda3 (fxmDA (0x0101010101017f01ULL), 3))); }
  { w (fxbDQ (__gnu_ashrdq3 (fxmDQ (0x3535353535353535ULL), 1))); }
  { w (fxbDQ (__gnu_ashrdq3 (fxmDQ (0x8181818181818181ULL), 2))); }
  { w (fxbDQ (__gnu_ashrdq3 (fxmDQ (0x0101010101017f01ULL), 3))); }
  { w (fxbHA (__gnu_ashrha3 (fxmHA (0x3535353535353535ULL), 1))); }
  { w (fxbHA (__gnu_ashrha3 (fxmHA (0x8181818181818181ULL), 2))); }
  { w (fxbHA (__gnu_ashrha3 (fxmHA (0x0101010101017f01ULL), 3))); }
  { w (fxbHQ (__gnu_ashrhq3 (fxmHQ (0x3535353535353535ULL), 1))); }
  { w (fxbHQ (__gnu_ashrhq3 (fxmHQ (0x8181818181818181ULL), 2))); }
  { w (fxbHQ (__gnu_ashrhq3 (fxmHQ (0x0101010101017f01ULL), 3))); }
  { w (fxbQQ (__gnu_ashrqq3 (fxmQQ (0x3535353535353535ULL), 1))); }
  { w (fxbQQ (__gnu_ashrqq3 (fxmQQ (0x8181818181818181ULL), 2))); }
  { w (fxbQQ (__gnu_ashrqq3 (fxmQQ (0x0101010101017f01ULL), 3))); }
  { w (fxbSA (__gnu_ashrsa3 (fxmSA (0x3535353535353535ULL), 1))); }
  { w (fxbSA (__gnu_ashrsa3 (fxmSA (0x8181818181818181ULL), 2))); }
  { w (fxbSA (__gnu_ashrsa3 (fxmSA (0x0101010101017f01ULL), 3))); }
  { w (fxbSQ (__gnu_ashrsq3 (fxmSQ (0x3535353535353535ULL), 1))); }
  { w (fxbSQ (__gnu_ashrsq3 (fxmSQ (0x8181818181818181ULL), 2))); }
  { w (fxbSQ (__gnu_ashrsq3 (fxmSQ (0x0101010101017f01ULL), 3))); }
  { w ((unsigned long long) __gnu_cmpda2 (fxmDA (0x3535353535353535ULL), fxmDA (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpda2 (fxmDA (0x8181818181818181ULL), fxmDA (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpda2 (fxmDA (0x0101010101017f01ULL), fxmDA (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmpdq2 (fxmDQ (0x3535353535353535ULL), fxmDQ (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpdq2 (fxmDQ (0x8181818181818181ULL), fxmDQ (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpdq2 (fxmDQ (0x0101010101017f01ULL), fxmDQ (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmpha2 (fxmHA (0x3535353535353535ULL), fxmHA (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpha2 (fxmHA (0x8181818181818181ULL), fxmHA (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpha2 (fxmHA (0x0101010101017f01ULL), fxmHA (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmphq2 (fxmHQ (0x3535353535353535ULL), fxmHQ (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmphq2 (fxmHQ (0x8181818181818181ULL), fxmHQ (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmphq2 (fxmHQ (0x0101010101017f01ULL), fxmHQ (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmpqq2 (fxmQQ (0x3535353535353535ULL), fxmQQ (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpqq2 (fxmQQ (0x8181818181818181ULL), fxmQQ (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpqq2 (fxmQQ (0x0101010101017f01ULL), fxmQQ (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmpsa2 (fxmSA (0x3535353535353535ULL), fxmSA (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpsa2 (fxmSA (0x8181818181818181ULL), fxmSA (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpsa2 (fxmSA (0x0101010101017f01ULL), fxmSA (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmpsq2 (fxmSQ (0x3535353535353535ULL), fxmSQ (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpsq2 (fxmSQ (0x8181818181818181ULL), fxmSQ (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpsq2 (fxmSQ (0x0101010101017f01ULL), fxmSQ (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmpuda2 (fxmUDA (0x3535353535353535ULL), fxmUDA (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpuda2 (fxmUDA (0x8181818181818181ULL), fxmUDA (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpuda2 (fxmUDA (0x0101010101017f01ULL), fxmUDA (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmpudq2 (fxmUDQ (0x3535353535353535ULL), fxmUDQ (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpudq2 (fxmUDQ (0x8181818181818181ULL), fxmUDQ (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpudq2 (fxmUDQ (0x0101010101017f01ULL), fxmUDQ (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmpuha2 (fxmUHA (0x3535353535353535ULL), fxmUHA (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpuha2 (fxmUHA (0x8181818181818181ULL), fxmUHA (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpuha2 (fxmUHA (0x0101010101017f01ULL), fxmUHA (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmpuhq2 (fxmUHQ (0x3535353535353535ULL), fxmUHQ (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpuhq2 (fxmUHQ (0x8181818181818181ULL), fxmUHQ (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpuhq2 (fxmUHQ (0x0101010101017f01ULL), fxmUHQ (0xc1c1c1c1c1c1c1c1ULL))); }
}
static void fxt3 (void) {
  double wg = 0.0; (void) wg;
  { w ((unsigned long long) __gnu_cmpuqq2 (fxmUQQ (0x3535353535353535ULL), fxmUQQ (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpuqq2 (fxmUQQ (0x8181818181818181ULL), fxmUQQ (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpuqq2 (fxmUQQ (0x0101010101017f01ULL), fxmUQQ (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmpusa2 (fxmUSA (0x3535353535353535ULL), fxmUSA (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpusa2 (fxmUSA (0x8181818181818181ULL), fxmUSA (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpusa2 (fxmUSA (0x0101010101017f01ULL), fxmUSA (0xc1c1c1c1c1c1c1c1ULL))); }
  { w ((unsigned long long) __gnu_cmpusq2 (fxmUSQ (0x3535353535353535ULL), fxmUSQ (0x2121212121212121ULL))); }
  { w ((unsigned long long) __gnu_cmpusq2 (fxmUSQ (0x8181818181818181ULL), fxmUSQ (0x0303030303030303ULL))); }
  { w ((unsigned long long) __gnu_cmpusq2 (fxmUSQ (0x0101010101017f01ULL), fxmUSQ (0xc1c1c1c1c1c1c1c1ULL))); }
  { w (fxbDA (__gnu_divda3 (fxmDA (0x3535353535353535ULL), fxmDA (0x2121212121212121ULL)))); }
  { w (fxbDA (__gnu_divda3 (fxmDA (0x8181818181818181ULL), fxmDA (0x0303030303030303ULL)))); }
  { w (fxbDA (__gnu_divda3 (fxmDA (0x0101010101017f01ULL), fxmDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDQ (__gnu_divdq3 (fxmDQ (0x3535353535353535ULL), fxmDQ (0x2121212121212121ULL)))); }
  { w (fxbDQ (__gnu_divdq3 (fxmDQ (0x8181818181818181ULL), fxmDQ (0x0303030303030303ULL)))); }
  { w (fxbDQ (__gnu_divdq3 (fxmDQ (0x0101010101017f01ULL), fxmDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHA (__gnu_divha3 (fxmHA (0x3535353535353535ULL), fxmHA (0x2121212121212121ULL)))); }
  { w (fxbHA (__gnu_divha3 (fxmHA (0x8181818181818181ULL), fxmHA (0x0303030303030303ULL)))); }
  { w (fxbHA (__gnu_divha3 (fxmHA (0x0101010101017f01ULL), fxmHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDA (__gnu_divhelperda (fxmDA (0x3535353535353535ULL), fxmDA (0x2121212121212121ULL), 0))); }
  { w (fxbDA (__gnu_divhelperda (fxmDA (0x8181818181818181ULL), fxmDA (0x0303030303030303ULL), 1))); }
  { w (fxbDA (__gnu_divhelperda (fxmDA (0x0101010101017f01ULL), fxmDA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbDQ (__gnu_divhelperdq (fxmDQ (0x3535353535353535ULL), fxmDQ (0x2121212121212121ULL), 0))); }
  { w (fxbDQ (__gnu_divhelperdq (fxmDQ (0x8181818181818181ULL), fxmDQ (0x0303030303030303ULL), 1))); }
  { w (fxbDQ (__gnu_divhelperdq (fxmDQ (0x0101010101017f01ULL), fxmDQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbHA (__gnu_divhelperha (fxmHA (0x3535353535353535ULL), fxmHA (0x2121212121212121ULL), 0))); }
  { w (fxbHA (__gnu_divhelperha (fxmHA (0x8181818181818181ULL), fxmHA (0x0303030303030303ULL), 1))); }
  { w (fxbHA (__gnu_divhelperha (fxmHA (0x0101010101017f01ULL), fxmHA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbHQ (__gnu_divhelperhq (fxmHQ (0x3535353535353535ULL), fxmHQ (0x2121212121212121ULL), 0))); }
  { w (fxbHQ (__gnu_divhelperhq (fxmHQ (0x8181818181818181ULL), fxmHQ (0x0303030303030303ULL), 1))); }
  { w (fxbHQ (__gnu_divhelperhq (fxmHQ (0x0101010101017f01ULL), fxmHQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbQQ (__gnu_divhelperqq (fxmQQ (0x3535353535353535ULL), fxmQQ (0x2121212121212121ULL), 0))); }
  { w (fxbQQ (__gnu_divhelperqq (fxmQQ (0x8181818181818181ULL), fxmQQ (0x0303030303030303ULL), 1))); }
  { w (fxbQQ (__gnu_divhelperqq (fxmQQ (0x0101010101017f01ULL), fxmQQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbSA (__gnu_divhelpersa (fxmSA (0x3535353535353535ULL), fxmSA (0x2121212121212121ULL), 0))); }
  { w (fxbSA (__gnu_divhelpersa (fxmSA (0x8181818181818181ULL), fxmSA (0x0303030303030303ULL), 1))); }
  { w (fxbSA (__gnu_divhelpersa (fxmSA (0x0101010101017f01ULL), fxmSA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbSQ (__gnu_divhelpersq (fxmSQ (0x3535353535353535ULL), fxmSQ (0x2121212121212121ULL), 0))); }
  { w (fxbSQ (__gnu_divhelpersq (fxmSQ (0x8181818181818181ULL), fxmSQ (0x0303030303030303ULL), 1))); }
  { w (fxbSQ (__gnu_divhelpersq (fxmSQ (0x0101010101017f01ULL), fxmSQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUDA (__gnu_divhelperuda (fxmUDA (0x3535353535353535ULL), fxmUDA (0x2121212121212121ULL), 0))); }
  { w (fxbUDA (__gnu_divhelperuda (fxmUDA (0x8181818181818181ULL), fxmUDA (0x0303030303030303ULL), 1))); }
  { w (fxbUDA (__gnu_divhelperuda (fxmUDA (0x0101010101017f01ULL), fxmUDA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUDQ (__gnu_divhelperudq (fxmUDQ (0x3535353535353535ULL), fxmUDQ (0x2121212121212121ULL), 0))); }
  { w (fxbUDQ (__gnu_divhelperudq (fxmUDQ (0x8181818181818181ULL), fxmUDQ (0x0303030303030303ULL), 1))); }
  { w (fxbUDQ (__gnu_divhelperudq (fxmUDQ (0x0101010101017f01ULL), fxmUDQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUHA (__gnu_divhelperuha (fxmUHA (0x3535353535353535ULL), fxmUHA (0x2121212121212121ULL), 0))); }
  { w (fxbUHA (__gnu_divhelperuha (fxmUHA (0x8181818181818181ULL), fxmUHA (0x0303030303030303ULL), 1))); }
  { w (fxbUHA (__gnu_divhelperuha (fxmUHA (0x0101010101017f01ULL), fxmUHA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUHQ (__gnu_divhelperuhq (fxmUHQ (0x3535353535353535ULL), fxmUHQ (0x2121212121212121ULL), 0))); }
  { w (fxbUHQ (__gnu_divhelperuhq (fxmUHQ (0x8181818181818181ULL), fxmUHQ (0x0303030303030303ULL), 1))); }
  { w (fxbUHQ (__gnu_divhelperuhq (fxmUHQ (0x0101010101017f01ULL), fxmUHQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUQQ (__gnu_divhelperuqq (fxmUQQ (0x3535353535353535ULL), fxmUQQ (0x2121212121212121ULL), 0))); }
  { w (fxbUQQ (__gnu_divhelperuqq (fxmUQQ (0x8181818181818181ULL), fxmUQQ (0x0303030303030303ULL), 1))); }
  { w (fxbUQQ (__gnu_divhelperuqq (fxmUQQ (0x0101010101017f01ULL), fxmUQQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUSA (__gnu_divhelperusa (fxmUSA (0x3535353535353535ULL), fxmUSA (0x2121212121212121ULL), 0))); }
  { w (fxbUSA (__gnu_divhelperusa (fxmUSA (0x8181818181818181ULL), fxmUSA (0x0303030303030303ULL), 1))); }
  { w (fxbUSA (__gnu_divhelperusa (fxmUSA (0x0101010101017f01ULL), fxmUSA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUSQ (__gnu_divhelperusq (fxmUSQ (0x3535353535353535ULL), fxmUSQ (0x2121212121212121ULL), 0))); }
  { w (fxbUSQ (__gnu_divhelperusq (fxmUSQ (0x8181818181818181ULL), fxmUSQ (0x0303030303030303ULL), 1))); }
  { w (fxbUSQ (__gnu_divhelperusq (fxmUSQ (0x0101010101017f01ULL), fxmUSQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
}
static void fxt4 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbHQ (__gnu_divhq3 (fxmHQ (0x3535353535353535ULL), fxmHQ (0x2121212121212121ULL)))); }
  { w (fxbHQ (__gnu_divhq3 (fxmHQ (0x8181818181818181ULL), fxmHQ (0x0303030303030303ULL)))); }
  { w (fxbHQ (__gnu_divhq3 (fxmHQ (0x0101010101017f01ULL), fxmHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbQQ (__gnu_divqq3 (fxmQQ (0x3535353535353535ULL), fxmQQ (0x2121212121212121ULL)))); }
  { w (fxbQQ (__gnu_divqq3 (fxmQQ (0x8181818181818181ULL), fxmQQ (0x0303030303030303ULL)))); }
  { w (fxbQQ (__gnu_divqq3 (fxmQQ (0x0101010101017f01ULL), fxmQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSA (__gnu_divsa3 (fxmSA (0x3535353535353535ULL), fxmSA (0x2121212121212121ULL)))); }
  { w (fxbSA (__gnu_divsa3 (fxmSA (0x8181818181818181ULL), fxmSA (0x0303030303030303ULL)))); }
  { w (fxbSA (__gnu_divsa3 (fxmSA (0x0101010101017f01ULL), fxmSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSQ (__gnu_divsq3 (fxmSQ (0x3535353535353535ULL), fxmSQ (0x2121212121212121ULL)))); }
  { w (fxbSQ (__gnu_divsq3 (fxmSQ (0x8181818181818181ULL), fxmSQ (0x0303030303030303ULL)))); }
  { w (fxbSQ (__gnu_divsq3 (fxmSQ (0x0101010101017f01ULL), fxmSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { d (__gnu_fractdadf (fxmDA (0x3535353535353535ULL))); }
  { d (__gnu_fractdadf (fxmDA (0x8181818181818181ULL))); }
  { d (__gnu_fractdadf (fxmDA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractdadi (fxmDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractdadi (fxmDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractdadi (fxmDA (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractdadq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fractdadq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fractdadq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_fractdaha2 (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractdaha2 (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractdaha2 (fxmDA (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractdahi (fxmDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractdahi (fxmDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractdahi (fxmDA (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractdahq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractdahq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractdahq (fxmDA (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractdaqi (fxmDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractdaqi (fxmDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractdaqi (fxmDA (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractdaqq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fractdaqq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fractdaqq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fractdasa2 (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fractdasa2 (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fractdasa2 (fxmDA (0x0101010101017f01ULL)))); }
  { f (__gnu_fractdasf (fxmDA (0x3535353535353535ULL))); }
  { f (__gnu_fractdasf (fxmDA (0x8181818181818181ULL))); }
  { f (__gnu_fractdasf (fxmDA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractdasi (fxmDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractdasi (fxmDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractdasi (fxmDA (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractdasq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fractdasq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fractdasq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_fractdauda (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fractdauda (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fractdauda (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fractdaudq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fractdaudq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fractdaudq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fractdauha (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fractdauha (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fractdauha (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fractdauhq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fractdauhq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fractdauhq (fxmDA (0x0101010101017f01ULL)))); }
}
static void fxt5 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUQQ (__gnu_fractdauqq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fractdauqq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fractdauqq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fractdausa (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fractdausa (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fractdausa (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fractdausq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fractdausq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fractdausq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_fractdfda (0.3))); }
  { w (fxbDA (__gnu_fractdfda (0.0625))); }
  { w (fxbDA (__gnu_fractdfda (0.4375))); }
  { w (fxbDQ (__gnu_fractdfdq (0.3))); }
  { w (fxbDQ (__gnu_fractdfdq (0.0625))); }
  { w (fxbDQ (__gnu_fractdfdq (0.4375))); }
  { w (fxbHA (__gnu_fractdfha (0.3))); }
  { w (fxbHA (__gnu_fractdfha (0.0625))); }
  { w (fxbHA (__gnu_fractdfha (0.4375))); }
  { w (fxbHQ (__gnu_fractdfhq (0.3))); }
  { w (fxbHQ (__gnu_fractdfhq (0.0625))); }
  { w (fxbHQ (__gnu_fractdfhq (0.4375))); }
  { w (fxbQQ (__gnu_fractdfqq (0.3))); }
  { w (fxbQQ (__gnu_fractdfqq (0.0625))); }
  { w (fxbQQ (__gnu_fractdfqq (0.4375))); }
  { w (fxbSA (__gnu_fractdfsa (0.3))); }
  { w (fxbSA (__gnu_fractdfsa (0.0625))); }
  { w (fxbSA (__gnu_fractdfsa (0.4375))); }
  { w (fxbSQ (__gnu_fractdfsq (0.3))); }
  { w (fxbSQ (__gnu_fractdfsq (0.0625))); }
  { w (fxbSQ (__gnu_fractdfsq (0.4375))); }
  { w (fxbUDA (__gnu_fractdfuda (0.3))); }
  { w (fxbUDA (__gnu_fractdfuda (0.0625))); }
  { w (fxbUDA (__gnu_fractdfuda (0.4375))); }
  { w (fxbUDQ (__gnu_fractdfudq (0.3))); }
  { w (fxbUDQ (__gnu_fractdfudq (0.0625))); }
  { w (fxbUDQ (__gnu_fractdfudq (0.4375))); }
  { w (fxbUHA (__gnu_fractdfuha (0.3))); }
  { w (fxbUHA (__gnu_fractdfuha (0.0625))); }
  { w (fxbUHA (__gnu_fractdfuha (0.4375))); }
  { w (fxbUHQ (__gnu_fractdfuhq (0.3))); }
  { w (fxbUHQ (__gnu_fractdfuhq (0.0625))); }
  { w (fxbUHQ (__gnu_fractdfuhq (0.4375))); }
  { w (fxbUQQ (__gnu_fractdfuqq (0.3))); }
  { w (fxbUQQ (__gnu_fractdfuqq (0.0625))); }
  { w (fxbUQQ (__gnu_fractdfuqq (0.4375))); }
  { w (fxbUSA (__gnu_fractdfusa (0.3))); }
  { w (fxbUSA (__gnu_fractdfusa (0.0625))); }
  { w (fxbUSA (__gnu_fractdfusa (0.4375))); }
  { w (fxbUSQ (__gnu_fractdfusq (0.3))); }
  { w (fxbUSQ (__gnu_fractdfusq (0.0625))); }
  { w (fxbUSQ (__gnu_fractdfusq (0.4375))); }
  { w (fxbDA (__gnu_fractdida ((DItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_fractdida ((DItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_fractdida ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractdidq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_fractdidq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_fractdidq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_fractdiha ((DItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_fractdiha ((DItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_fractdiha ((DItype) 0x0101010101017f01ULL))); }
}
static void fxt6 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbHQ (__gnu_fractdihq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_fractdihq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_fractdihq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractdiqq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_fractdiqq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_fractdiqq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_fractdisa ((DItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_fractdisa ((DItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_fractdisa ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractdisq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_fractdisq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_fractdisq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_fractdiuda ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_fractdiuda ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_fractdiuda ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_fractdiudq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_fractdiudq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_fractdiudq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_fractdiuha ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_fractdiuha ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_fractdiuha ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_fractdiuhq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_fractdiuhq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_fractdiuhq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_fractdiuqq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_fractdiuqq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_fractdiuqq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_fractdiusa ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_fractdiusa ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_fractdiusa ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_fractdiusq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_fractdiusq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_fractdiusq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_fractdqda (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fractdqda (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fractdqda (fxmDQ (0x0101010101017f01ULL)))); }
  { d (__gnu_fractdqdf (fxmDQ (0x3535353535353535ULL))); }
  { d (__gnu_fractdqdf (fxmDQ (0x8181818181818181ULL))); }
  { d (__gnu_fractdqdf (fxmDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractdqdi (fxmDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractdqdi (fxmDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractdqdi (fxmDQ (0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_fractdqha (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractdqha (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractdqha (fxmDQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractdqhi (fxmDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractdqhi (fxmDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractdqhi (fxmDQ (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractdqhq2 (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractdqhq2 (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractdqhq2 (fxmDQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractdqqi (fxmDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractdqqi (fxmDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractdqqi (fxmDQ (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractdqqq2 (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fractdqqq2 (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fractdqqq2 (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fractdqsa (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fractdqsa (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fractdqsa (fxmDQ (0x0101010101017f01ULL)))); }
}
static void fxt7 (void) {
  double wg = 0.0; (void) wg;
  { f (__gnu_fractdqsf (fxmDQ (0x3535353535353535ULL))); }
  { f (__gnu_fractdqsf (fxmDQ (0x8181818181818181ULL))); }
  { f (__gnu_fractdqsf (fxmDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractdqsi (fxmDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractdqsi (fxmDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractdqsi (fxmDQ (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractdqsq2 (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fractdqsq2 (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fractdqsq2 (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_fractdquda (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fractdquda (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fractdquda (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fractdqudq (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fractdqudq (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fractdqudq (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fractdquha (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fractdquha (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fractdquha (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fractdquhq (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fractdquhq (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fractdquhq (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fractdquqq (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fractdquqq (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fractdquqq (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fractdqusa (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fractdqusa (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fractdqusa (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fractdqusq (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fractdqusq (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fractdqusq (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_fracthada2 (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fracthada2 (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fracthada2 (fxmHA (0x0101010101017f01ULL)))); }
  { d (__gnu_fracthadf (fxmHA (0x3535353535353535ULL))); }
  { d (__gnu_fracthadf (fxmHA (0x8181818181818181ULL))); }
  { d (__gnu_fracthadf (fxmHA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fracthadi (fxmHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fracthadi (fxmHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fracthadi (fxmHA (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fracthadq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fracthadq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fracthadq (fxmHA (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fracthahi (fxmHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fracthahi (fxmHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fracthahi (fxmHA (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fracthahq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fracthahq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fracthahq (fxmHA (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fracthaqi (fxmHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fracthaqi (fxmHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fracthaqi (fxmHA (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fracthaqq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fracthaqq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fracthaqq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fracthasa2 (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fracthasa2 (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fracthasa2 (fxmHA (0x0101010101017f01ULL)))); }
  { f (__gnu_fracthasf (fxmHA (0x3535353535353535ULL))); }
  { f (__gnu_fracthasf (fxmHA (0x8181818181818181ULL))); }
  { f (__gnu_fracthasf (fxmHA (0x0101010101017f01ULL))); }
}
static void fxt8 (void) {
  double wg = 0.0; (void) wg;
  { w ((unsigned long long) __gnu_fracthasi (fxmHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fracthasi (fxmHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fracthasi (fxmHA (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fracthasq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fracthasq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fracthasq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_fracthauda (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fracthauda (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fracthauda (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fracthaudq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fracthaudq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fracthaudq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fracthauha (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fracthauha (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fracthauha (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fracthauhq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fracthauhq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fracthauhq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fracthauqq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fracthauqq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fracthauqq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fracthausa (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fracthausa (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fracthausa (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fracthausq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fracthausq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fracthausq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_fracthida ((HItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_fracthida ((HItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_fracthida ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fracthidq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_fracthidq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_fracthidq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_fracthiha ((HItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_fracthiha ((HItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_fracthiha ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fracthihq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_fracthihq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_fracthihq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fracthiqq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_fracthiqq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_fracthiqq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_fracthisa ((HItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_fracthisa ((HItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_fracthisa ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fracthisq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_fracthisq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_fracthisq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_fracthiuda ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_fracthiuda ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_fracthiuda ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_fracthiudq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_fracthiudq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_fracthiudq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_fracthiuha ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_fracthiuha ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_fracthiuha ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_fracthiuhq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_fracthiuhq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_fracthiuhq ((HItype) 0x0101010101017f01ULL))); }
}
static void fxt9 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUQQ (__gnu_fracthiuqq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_fracthiuqq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_fracthiuqq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_fracthiusa ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_fracthiusa ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_fracthiusa ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_fracthiusq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_fracthiusq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_fracthiusq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_fracthqda (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fracthqda (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fracthqda (fxmHQ (0x0101010101017f01ULL)))); }
  { d (__gnu_fracthqdf (fxmHQ (0x3535353535353535ULL))); }
  { d (__gnu_fracthqdf (fxmHQ (0x8181818181818181ULL))); }
  { d (__gnu_fracthqdf (fxmHQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fracthqdi (fxmHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fracthqdi (fxmHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fracthqdi (fxmHQ (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fracthqdq2 (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fracthqdq2 (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fracthqdq2 (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_fracthqha (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fracthqha (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fracthqha (fxmHQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fracthqhi (fxmHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fracthqhi (fxmHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fracthqhi (fxmHQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fracthqqi (fxmHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fracthqqi (fxmHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fracthqqi (fxmHQ (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fracthqqq2 (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fracthqqq2 (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fracthqqq2 (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fracthqsa (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fracthqsa (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fracthqsa (fxmHQ (0x0101010101017f01ULL)))); }
  { f (__gnu_fracthqsf (fxmHQ (0x3535353535353535ULL))); }
  { f (__gnu_fracthqsf (fxmHQ (0x8181818181818181ULL))); }
  { f (__gnu_fracthqsf (fxmHQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fracthqsi (fxmHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fracthqsi (fxmHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fracthqsi (fxmHQ (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fracthqsq2 (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fracthqsq2 (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fracthqsq2 (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_fracthquda (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fracthquda (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fracthquda (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fracthqudq (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fracthqudq (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fracthqudq (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fracthquha (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fracthquha (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fracthquha (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fracthquhq (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fracthquhq (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fracthquhq (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fracthquqq (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fracthquqq (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fracthquqq (fxmHQ (0x0101010101017f01ULL)))); }
}
static void fxt10 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUSA (__gnu_fracthqusa (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fracthqusa (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fracthqusa (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fracthqusq (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fracthqusq (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fracthqusq (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_fractqida ((QItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_fractqida ((QItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_fractqida ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractqidq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_fractqidq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_fractqidq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_fractqiha ((QItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_fractqiha ((QItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_fractqiha ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractqihq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_fractqihq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_fractqihq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractqiqq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_fractqiqq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_fractqiqq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_fractqisa ((QItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_fractqisa ((QItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_fractqisa ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractqisq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_fractqisq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_fractqisq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_fractqiuda ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_fractqiuda ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_fractqiuda ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_fractqiudq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_fractqiudq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_fractqiudq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_fractqiuha ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_fractqiuha ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_fractqiuha ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_fractqiuhq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_fractqiuhq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_fractqiuhq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_fractqiuqq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_fractqiuqq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_fractqiuqq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_fractqiusa ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_fractqiusa ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_fractqiusa ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_fractqiusq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_fractqiusq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_fractqiusq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_fractqqda (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fractqqda (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fractqqda (fxmQQ (0x0101010101017f01ULL)))); }
  { d (__gnu_fractqqdf (fxmQQ (0x3535353535353535ULL))); }
  { d (__gnu_fractqqdf (fxmQQ (0x8181818181818181ULL))); }
  { d (__gnu_fractqqdf (fxmQQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractqqdi (fxmQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractqqdi (fxmQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractqqdi (fxmQQ (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractqqdq2 (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fractqqdq2 (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fractqqdq2 (fxmQQ (0x0101010101017f01ULL)))); }
}
static void fxt11 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbHA (__gnu_fractqqha (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractqqha (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractqqha (fxmQQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractqqhi (fxmQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractqqhi (fxmQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractqqhi (fxmQQ (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractqqhq2 (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractqqhq2 (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractqqhq2 (fxmQQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractqqqi (fxmQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractqqqi (fxmQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractqqqi (fxmQQ (0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_fractqqsa (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fractqqsa (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fractqqsa (fxmQQ (0x0101010101017f01ULL)))); }
  { f (__gnu_fractqqsf (fxmQQ (0x3535353535353535ULL))); }
  { f (__gnu_fractqqsf (fxmQQ (0x8181818181818181ULL))); }
  { f (__gnu_fractqqsf (fxmQQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractqqsi (fxmQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractqqsi (fxmQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractqqsi (fxmQQ (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractqqsq2 (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fractqqsq2 (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fractqqsq2 (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_fractqquda (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fractqquda (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fractqquda (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fractqqudq (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fractqqudq (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fractqqudq (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fractqquha (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fractqquha (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fractqquha (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fractqquhq (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fractqquhq (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fractqquhq (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fractqquqq (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fractqquqq (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fractqquqq (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fractqqusa (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fractqqusa (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fractqqusa (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fractqqusq (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fractqqusq (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fractqqusq (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_fractsada2 (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fractsada2 (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fractsada2 (fxmSA (0x0101010101017f01ULL)))); }
  { d (__gnu_fractsadf (fxmSA (0x3535353535353535ULL))); }
  { d (__gnu_fractsadf (fxmSA (0x8181818181818181ULL))); }
  { d (__gnu_fractsadf (fxmSA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractsadi (fxmSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractsadi (fxmSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractsadi (fxmSA (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractsadq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fractsadq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fractsadq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_fractsaha2 (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractsaha2 (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractsaha2 (fxmSA (0x0101010101017f01ULL)))); }
}
static void fxt12 (void) {
  double wg = 0.0; (void) wg;
  { w ((unsigned long long) __gnu_fractsahi (fxmSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractsahi (fxmSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractsahi (fxmSA (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractsahq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractsahq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractsahq (fxmSA (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractsaqi (fxmSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractsaqi (fxmSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractsaqi (fxmSA (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractsaqq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fractsaqq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fractsaqq (fxmSA (0x0101010101017f01ULL)))); }
  { f (__gnu_fractsasf (fxmSA (0x3535353535353535ULL))); }
  { f (__gnu_fractsasf (fxmSA (0x8181818181818181ULL))); }
  { f (__gnu_fractsasf (fxmSA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractsasi (fxmSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractsasi (fxmSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractsasi (fxmSA (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractsasq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fractsasq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fractsasq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_fractsauda (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fractsauda (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fractsauda (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fractsaudq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fractsaudq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fractsaudq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fractsauha (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fractsauha (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fractsauha (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fractsauhq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fractsauhq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fractsauhq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fractsauqq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fractsauqq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fractsauqq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fractsausa (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fractsausa (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fractsausa (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fractsausq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fractsausq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fractsausq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_fractsfda (0.3f))); }
  { w (fxbDA (__gnu_fractsfda (0.0625f))); }
  { w (fxbDA (__gnu_fractsfda (0.4375f))); }
  { w (fxbDQ (__gnu_fractsfdq (0.3f))); }
  { w (fxbDQ (__gnu_fractsfdq (0.0625f))); }
  { w (fxbDQ (__gnu_fractsfdq (0.4375f))); }
  { w (fxbHA (__gnu_fractsfha (0.3f))); }
  { w (fxbHA (__gnu_fractsfha (0.0625f))); }
  { w (fxbHA (__gnu_fractsfha (0.4375f))); }
  { w (fxbHQ (__gnu_fractsfhq (0.3f))); }
  { w (fxbHQ (__gnu_fractsfhq (0.0625f))); }
  { w (fxbHQ (__gnu_fractsfhq (0.4375f))); }
  { w (fxbQQ (__gnu_fractsfqq (0.3f))); }
  { w (fxbQQ (__gnu_fractsfqq (0.0625f))); }
  { w (fxbQQ (__gnu_fractsfqq (0.4375f))); }
  { w (fxbSA (__gnu_fractsfsa (0.3f))); }
  { w (fxbSA (__gnu_fractsfsa (0.0625f))); }
  { w (fxbSA (__gnu_fractsfsa (0.4375f))); }
}
static void fxt13 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbSQ (__gnu_fractsfsq (0.3f))); }
  { w (fxbSQ (__gnu_fractsfsq (0.0625f))); }
  { w (fxbSQ (__gnu_fractsfsq (0.4375f))); }
  { w (fxbUDA (__gnu_fractsfuda (0.3f))); }
  { w (fxbUDA (__gnu_fractsfuda (0.0625f))); }
  { w (fxbUDA (__gnu_fractsfuda (0.4375f))); }
  { w (fxbUDQ (__gnu_fractsfudq (0.3f))); }
  { w (fxbUDQ (__gnu_fractsfudq (0.0625f))); }
  { w (fxbUDQ (__gnu_fractsfudq (0.4375f))); }
  { w (fxbUHA (__gnu_fractsfuha (0.3f))); }
  { w (fxbUHA (__gnu_fractsfuha (0.0625f))); }
  { w (fxbUHA (__gnu_fractsfuha (0.4375f))); }
  { w (fxbUHQ (__gnu_fractsfuhq (0.3f))); }
  { w (fxbUHQ (__gnu_fractsfuhq (0.0625f))); }
  { w (fxbUHQ (__gnu_fractsfuhq (0.4375f))); }
  { w (fxbUQQ (__gnu_fractsfuqq (0.3f))); }
  { w (fxbUQQ (__gnu_fractsfuqq (0.0625f))); }
  { w (fxbUQQ (__gnu_fractsfuqq (0.4375f))); }
  { w (fxbUSA (__gnu_fractsfusa (0.3f))); }
  { w (fxbUSA (__gnu_fractsfusa (0.0625f))); }
  { w (fxbUSA (__gnu_fractsfusa (0.4375f))); }
  { w (fxbUSQ (__gnu_fractsfusq (0.3f))); }
  { w (fxbUSQ (__gnu_fractsfusq (0.0625f))); }
  { w (fxbUSQ (__gnu_fractsfusq (0.4375f))); }
  { w (fxbDA (__gnu_fractsida ((SItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_fractsida ((SItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_fractsida ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractsidq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_fractsidq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_fractsidq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_fractsiha ((SItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_fractsiha ((SItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_fractsiha ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractsihq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_fractsihq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_fractsihq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractsiqq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_fractsiqq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_fractsiqq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_fractsisa ((SItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_fractsisa ((SItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_fractsisa ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractsisq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_fractsisq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_fractsisq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_fractsiuda ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_fractsiuda ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_fractsiuda ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_fractsiudq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_fractsiudq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_fractsiudq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_fractsiuha ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_fractsiuha ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_fractsiuha ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_fractsiuhq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_fractsiuhq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_fractsiuhq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_fractsiuqq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_fractsiuqq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_fractsiuqq ((SItype) 0x0101010101017f01ULL))); }
}
static void fxt14 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUSA (__gnu_fractsiusa ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_fractsiusa ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_fractsiusa ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_fractsiusq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_fractsiusq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_fractsiusq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_fractsqda (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fractsqda (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fractsqda (fxmSQ (0x0101010101017f01ULL)))); }
  { d (__gnu_fractsqdf (fxmSQ (0x3535353535353535ULL))); }
  { d (__gnu_fractsqdf (fxmSQ (0x8181818181818181ULL))); }
  { d (__gnu_fractsqdf (fxmSQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractsqdi (fxmSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractsqdi (fxmSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractsqdi (fxmSQ (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractsqdq2 (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fractsqdq2 (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fractsqdq2 (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_fractsqha (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractsqha (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractsqha (fxmSQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractsqhi (fxmSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractsqhi (fxmSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractsqhi (fxmSQ (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractsqhq2 (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractsqhq2 (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractsqhq2 (fxmSQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractsqqi (fxmSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractsqqi (fxmSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractsqqi (fxmSQ (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractsqqq2 (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fractsqqq2 (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fractsqqq2 (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fractsqsa (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fractsqsa (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fractsqsa (fxmSQ (0x0101010101017f01ULL)))); }
  { f (__gnu_fractsqsf (fxmSQ (0x3535353535353535ULL))); }
  { f (__gnu_fractsqsf (fxmSQ (0x8181818181818181ULL))); }
  { f (__gnu_fractsqsf (fxmSQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractsqsi (fxmSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractsqsi (fxmSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractsqsi (fxmSQ (0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_fractsquda (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fractsquda (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fractsquda (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fractsqudq (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fractsqudq (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fractsqudq (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fractsquha (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fractsquha (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fractsquha (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fractsquhq (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fractsquhq (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fractsquhq (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fractsquqq (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fractsquqq (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fractsquqq (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fractsqusa (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fractsqusa (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fractsqusa (fxmSQ (0x0101010101017f01ULL)))); }
}
static void fxt15 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUSQ (__gnu_fractsqusq (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fractsqusq (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fractsqusq (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_fractudada (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fractudada (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fractudada (fxmUDA (0x0101010101017f01ULL)))); }
  { d (__gnu_fractudadf (fxmUDA (0x3535353535353535ULL))); }
  { d (__gnu_fractudadf (fxmUDA (0x8181818181818181ULL))); }
  { d (__gnu_fractudadf (fxmUDA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractudadi (fxmUDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractudadi (fxmUDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractudadi (fxmUDA (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractudadq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fractudadq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fractudadq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_fractudaha (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractudaha (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractudaha (fxmUDA (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractudahi (fxmUDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractudahi (fxmUDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractudahi (fxmUDA (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractudahq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractudahq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractudahq (fxmUDA (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractudaqi (fxmUDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractudaqi (fxmUDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractudaqi (fxmUDA (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractudaqq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fractudaqq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fractudaqq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fractudasa (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fractudasa (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fractudasa (fxmUDA (0x0101010101017f01ULL)))); }
  { f (__gnu_fractudasf (fxmUDA (0x3535353535353535ULL))); }
  { f (__gnu_fractudasf (fxmUDA (0x8181818181818181ULL))); }
  { f (__gnu_fractudasf (fxmUDA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractudasi (fxmUDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractudasi (fxmUDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractudasi (fxmUDA (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractudasq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fractudasq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fractudasq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fractudaudq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fractudaudq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fractudaudq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fractudauha2 (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fractudauha2 (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fractudauha2 (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fractudauhq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fractudauhq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fractudauhq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fractudauqq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fractudauqq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fractudauqq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fractudausa2 (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fractudausa2 (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fractudausa2 (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fractudausq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fractudausq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fractudausq (fxmUDA (0x0101010101017f01ULL)))); }
}
static void fxt16 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbDA (__gnu_fractudqda (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fractudqda (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fractudqda (fxmUDQ (0x0101010101017f01ULL)))); }
  { d (__gnu_fractudqdf (fxmUDQ (0x3535353535353535ULL))); }
  { d (__gnu_fractudqdf (fxmUDQ (0x8181818181818181ULL))); }
  { d (__gnu_fractudqdf (fxmUDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractudqdi (fxmUDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractudqdi (fxmUDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractudqdi (fxmUDQ (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractudqdq (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fractudqdq (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fractudqdq (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_fractudqha (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractudqha (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractudqha (fxmUDQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractudqhi (fxmUDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractudqhi (fxmUDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractudqhi (fxmUDQ (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractudqhq (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractudqhq (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractudqhq (fxmUDQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractudqqi (fxmUDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractudqqi (fxmUDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractudqqi (fxmUDQ (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractudqqq (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fractudqqq (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fractudqqq (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fractudqsa (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fractudqsa (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fractudqsa (fxmUDQ (0x0101010101017f01ULL)))); }
  { f (__gnu_fractudqsf (fxmUDQ (0x3535353535353535ULL))); }
  { f (__gnu_fractudqsf (fxmUDQ (0x8181818181818181ULL))); }
  { f (__gnu_fractudqsf (fxmUDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractudqsi (fxmUDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractudqsi (fxmUDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractudqsi (fxmUDQ (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractudqsq (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fractudqsq (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fractudqsq (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_fractudquda (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fractudquda (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fractudquda (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fractudquha (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fractudquha (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fractudquha (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fractudquhq2 (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fractudquhq2 (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fractudquhq2 (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fractudquqq2 (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fractudquqq2 (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fractudquqq2 (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fractudqusa (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fractudqusa (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fractudqusa (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fractudqusq2 (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fractudqusq2 (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fractudqusq2 (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_fractuhada (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fractuhada (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fractuhada (fxmUHA (0x0101010101017f01ULL)))); }
}
static void fxt17 (void) {
  double wg = 0.0; (void) wg;
  { d (__gnu_fractuhadf (fxmUHA (0x3535353535353535ULL))); }
  { d (__gnu_fractuhadf (fxmUHA (0x8181818181818181ULL))); }
  { d (__gnu_fractuhadf (fxmUHA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractuhadi (fxmUHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuhadi (fxmUHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuhadi (fxmUHA (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractuhadq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fractuhadq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fractuhadq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_fractuhaha (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractuhaha (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractuhaha (fxmUHA (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractuhahi (fxmUHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuhahi (fxmUHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuhahi (fxmUHA (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractuhahq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractuhahq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractuhahq (fxmUHA (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractuhaqi (fxmUHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuhaqi (fxmUHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuhaqi (fxmUHA (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractuhaqq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fractuhaqq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fractuhaqq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fractuhasa (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fractuhasa (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fractuhasa (fxmUHA (0x0101010101017f01ULL)))); }
  { f (__gnu_fractuhasf (fxmUHA (0x3535353535353535ULL))); }
  { f (__gnu_fractuhasf (fxmUHA (0x8181818181818181ULL))); }
  { f (__gnu_fractuhasf (fxmUHA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractuhasi (fxmUHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuhasi (fxmUHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuhasi (fxmUHA (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractuhasq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fractuhasq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fractuhasq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_fractuhauda2 (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fractuhauda2 (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fractuhauda2 (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fractuhaudq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fractuhaudq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fractuhaudq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fractuhauhq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fractuhauhq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fractuhauhq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fractuhauqq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fractuhauqq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fractuhauqq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fractuhausa2 (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fractuhausa2 (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fractuhausa2 (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fractuhausq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fractuhausq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fractuhausq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_fractuhqda (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fractuhqda (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fractuhqda (fxmUHQ (0x0101010101017f01ULL)))); }
  { d (__gnu_fractuhqdf (fxmUHQ (0x3535353535353535ULL))); }
  { d (__gnu_fractuhqdf (fxmUHQ (0x8181818181818181ULL))); }
  { d (__gnu_fractuhqdf (fxmUHQ (0x0101010101017f01ULL))); }
}
static void fxt18 (void) {
  double wg = 0.0; (void) wg;
  { w ((unsigned long long) __gnu_fractuhqdi (fxmUHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuhqdi (fxmUHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuhqdi (fxmUHQ (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractuhqdq (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fractuhqdq (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fractuhqdq (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_fractuhqha (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractuhqha (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractuhqha (fxmUHQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractuhqhi (fxmUHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuhqhi (fxmUHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuhqhi (fxmUHQ (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractuhqhq (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractuhqhq (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractuhqhq (fxmUHQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractuhqqi (fxmUHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuhqqi (fxmUHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuhqqi (fxmUHQ (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractuhqqq (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fractuhqqq (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fractuhqqq (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fractuhqsa (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fractuhqsa (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fractuhqsa (fxmUHQ (0x0101010101017f01ULL)))); }
  { f (__gnu_fractuhqsf (fxmUHQ (0x3535353535353535ULL))); }
  { f (__gnu_fractuhqsf (fxmUHQ (0x8181818181818181ULL))); }
  { f (__gnu_fractuhqsf (fxmUHQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractuhqsi (fxmUHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuhqsi (fxmUHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuhqsi (fxmUHQ (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractuhqsq (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fractuhqsq (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fractuhqsq (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_fractuhquda (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fractuhquda (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fractuhquda (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fractuhqudq2 (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fractuhqudq2 (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fractuhqudq2 (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fractuhquha (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fractuhquha (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fractuhquha (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fractuhquqq2 (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fractuhquqq2 (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fractuhquqq2 (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fractuhqusa (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fractuhqusa (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fractuhqusa (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fractuhqusq2 (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fractuhqusq2 (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fractuhqusq2 (fxmUHQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractunsdadi (fxmDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsdadi (fxmDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsdadi (fxmDA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsdahi (fxmDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsdahi (fxmDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsdahi (fxmDA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsdaqi (fxmDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsdaqi (fxmDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsdaqi (fxmDA (0x0101010101017f01ULL))); }
}
static void fxt19 (void) {
  double wg = 0.0; (void) wg;
  { w ((unsigned long long) __gnu_fractunsdasi (fxmDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsdasi (fxmDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsdasi (fxmDA (0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_fractunsdida ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_fractunsdida ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_fractunsdida ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractunsdidq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_fractunsdidq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_fractunsdidq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_fractunsdiha ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_fractunsdiha ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_fractunsdiha ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractunsdihq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_fractunsdihq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_fractunsdihq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractunsdiqq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_fractunsdiqq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_fractunsdiqq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_fractunsdisa ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_fractunsdisa ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_fractunsdisa ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractunsdisq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_fractunsdisq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_fractunsdisq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_fractunsdiuda ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_fractunsdiuda ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_fractunsdiuda ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_fractunsdiudq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_fractunsdiudq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_fractunsdiudq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_fractunsdiuha ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_fractunsdiuha ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_fractunsdiuha ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_fractunsdiuhq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_fractunsdiuhq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_fractunsdiuhq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_fractunsdiuqq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_fractunsdiuqq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_fractunsdiuqq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_fractunsdiusa ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_fractunsdiusa ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_fractunsdiusa ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_fractunsdiusq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_fractunsdiusq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_fractunsdiusq ((UDItype) 0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqdi (fxmDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqdi (fxmDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqdi (fxmDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqhi (fxmDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqhi (fxmDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqhi (fxmDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqqi (fxmDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqqi (fxmDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqqi (fxmDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqsi (fxmDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqsi (fxmDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsdqsi (fxmDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunshadi (fxmHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunshadi (fxmHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunshadi (fxmHA (0x0101010101017f01ULL))); }
}
static void fxt20 (void) {
  double wg = 0.0; (void) wg;
  { w ((unsigned long long) __gnu_fractunshahi (fxmHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunshahi (fxmHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunshahi (fxmHA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunshaqi (fxmHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunshaqi (fxmHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunshaqi (fxmHA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunshasi (fxmHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunshasi (fxmHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunshasi (fxmHA (0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_fractunshida ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_fractunshida ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_fractunshida ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractunshidq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_fractunshidq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_fractunshidq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_fractunshiha ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_fractunshiha ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_fractunshiha ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractunshihq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_fractunshihq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_fractunshihq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractunshiqq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_fractunshiqq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_fractunshiqq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_fractunshisa ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_fractunshisa ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_fractunshisa ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractunshisq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_fractunshisq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_fractunshisq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_fractunshiuda ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_fractunshiuda ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_fractunshiuda ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_fractunshiudq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_fractunshiudq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_fractunshiudq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_fractunshiuha ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_fractunshiuha ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_fractunshiuha ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_fractunshiuhq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_fractunshiuhq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_fractunshiuhq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_fractunshiuqq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_fractunshiuqq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_fractunshiuqq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_fractunshiusa ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_fractunshiusa ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_fractunshiusa ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_fractunshiusq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_fractunshiusq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_fractunshiusq ((UHItype) 0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunshqdi (fxmHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunshqdi (fxmHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunshqdi (fxmHQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunshqhi (fxmHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunshqhi (fxmHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunshqhi (fxmHQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunshqqi (fxmHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunshqqi (fxmHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunshqqi (fxmHQ (0x0101010101017f01ULL))); }
}
static void fxt21 (void) {
  double wg = 0.0; (void) wg;
  { w ((unsigned long long) __gnu_fractunshqsi (fxmHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunshqsi (fxmHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunshqsi (fxmHQ (0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_fractunsqida ((QItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_fractunsqida ((QItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_fractunsqida ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractunsqidq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_fractunsqidq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_fractunsqidq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_fractunsqiha ((QItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_fractunsqiha ((QItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_fractunsqiha ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractunsqihq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_fractunsqihq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_fractunsqihq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractunsqiqq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_fractunsqiqq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_fractunsqiqq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_fractunsqisa ((QItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_fractunsqisa ((QItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_fractunsqisa ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractunsqisq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_fractunsqisq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_fractunsqisq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_fractunsqiuda ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_fractunsqiuda ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_fractunsqiuda ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_fractunsqiudq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_fractunsqiudq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_fractunsqiudq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_fractunsqiuha ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_fractunsqiuha ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_fractunsqiuha ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_fractunsqiuhq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_fractunsqiuhq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_fractunsqiuhq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_fractunsqiuqq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_fractunsqiuqq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_fractunsqiuqq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_fractunsqiusa ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_fractunsqiusa ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_fractunsqiusa ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_fractunsqiusq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_fractunsqiusq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_fractunsqiusq ((QItype) 0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqdi (fxmQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqdi (fxmQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqdi (fxmQQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqhi (fxmQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqhi (fxmQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqhi (fxmQQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqqi (fxmQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqqi (fxmQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqqi (fxmQQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqsi (fxmQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqsi (fxmQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsqqsi (fxmQQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunssadi (fxmSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunssadi (fxmSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunssadi (fxmSA (0x0101010101017f01ULL))); }
}
static void fxt22 (void) {
  double wg = 0.0; (void) wg;
  { w ((unsigned long long) __gnu_fractunssahi (fxmSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunssahi (fxmSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunssahi (fxmSA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunssaqi (fxmSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunssaqi (fxmSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunssaqi (fxmSA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunssasi (fxmSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunssasi (fxmSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunssasi (fxmSA (0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_fractunssida ((USItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_fractunssida ((USItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_fractunssida ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractunssidq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_fractunssidq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_fractunssidq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_fractunssiha ((USItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_fractunssiha ((USItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_fractunssiha ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractunssihq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_fractunssihq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_fractunssihq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractunssiqq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_fractunssiqq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_fractunssiqq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_fractunssisa ((USItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_fractunssisa ((USItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_fractunssisa ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractunssisq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_fractunssisq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_fractunssisq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_fractunssiuda ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_fractunssiuda ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_fractunssiuda ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_fractunssiudq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_fractunssiudq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_fractunssiudq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_fractunssiuha ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_fractunssiuha ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_fractunssiuha ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_fractunssiuhq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_fractunssiuhq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_fractunssiuhq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_fractunssiuqq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_fractunssiuqq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_fractunssiuqq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_fractunssiusa ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_fractunssiusa ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_fractunssiusa ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_fractunssiusq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_fractunssiusq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_fractunssiusq ((USItype) 0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunssqdi (fxmSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunssqdi (fxmSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunssqdi (fxmSQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunssqhi (fxmSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunssqhi (fxmSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunssqhi (fxmSQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunssqqi (fxmSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunssqqi (fxmSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunssqqi (fxmSQ (0x0101010101017f01ULL))); }
}
static void fxt23 (void) {
  double wg = 0.0; (void) wg;
  { w ((unsigned long long) __gnu_fractunssqsi (fxmSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunssqsi (fxmSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunssqsi (fxmSQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsudadi (fxmUDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsudadi (fxmUDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsudadi (fxmUDA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsudahi (fxmUDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsudahi (fxmUDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsudahi (fxmUDA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsudaqi (fxmUDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsudaqi (fxmUDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsudaqi (fxmUDA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsudasi (fxmUDA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsudasi (fxmUDA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsudasi (fxmUDA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqdi (fxmUDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqdi (fxmUDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqdi (fxmUDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqhi (fxmUDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqhi (fxmUDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqhi (fxmUDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqqi (fxmUDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqqi (fxmUDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqqi (fxmUDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqsi (fxmUDQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqsi (fxmUDQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsudqsi (fxmUDQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhadi (fxmUHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhadi (fxmUHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhadi (fxmUHA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhahi (fxmUHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhahi (fxmUHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhahi (fxmUHA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhaqi (fxmUHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhaqi (fxmUHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhaqi (fxmUHA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhasi (fxmUHA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhasi (fxmUHA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhasi (fxmUHA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqdi (fxmUHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqdi (fxmUHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqdi (fxmUHQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqhi (fxmUHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqhi (fxmUHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqhi (fxmUHQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqqi (fxmUHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqqi (fxmUHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqqi (fxmUHQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqsi (fxmUHQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqsi (fxmUHQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuhqsi (fxmUHQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsuqqdi (fxmUQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuqqdi (fxmUQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuqqdi (fxmUQQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsuqqhi (fxmUQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuqqhi (fxmUQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuqqhi (fxmUQQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsuqqqi (fxmUQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuqqqi (fxmUQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuqqqi (fxmUQQ (0x0101010101017f01ULL))); }
}
static void fxt24 (void) {
  double wg = 0.0; (void) wg;
  { w ((unsigned long long) __gnu_fractunsuqqsi (fxmUQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsuqqsi (fxmUQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsuqqsi (fxmUQQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsusadi (fxmUSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsusadi (fxmUSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsusadi (fxmUSA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsusahi (fxmUSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsusahi (fxmUSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsusahi (fxmUSA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsusaqi (fxmUSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsusaqi (fxmUSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsusaqi (fxmUSA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsusasi (fxmUSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsusasi (fxmUSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsusasi (fxmUSA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqdi (fxmUSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqdi (fxmUSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqdi (fxmUSQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqhi (fxmUSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqhi (fxmUSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqhi (fxmUSQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqqi (fxmUSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqqi (fxmUSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqqi (fxmUSQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqsi (fxmUSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqsi (fxmUSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractunsusqsi (fxmUSQ (0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_fractuqqda (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fractuqqda (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fractuqqda (fxmUQQ (0x0101010101017f01ULL)))); }
  { d (__gnu_fractuqqdf (fxmUQQ (0x3535353535353535ULL))); }
  { d (__gnu_fractuqqdf (fxmUQQ (0x8181818181818181ULL))); }
  { d (__gnu_fractuqqdf (fxmUQQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractuqqdi (fxmUQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuqqdi (fxmUQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuqqdi (fxmUQQ (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractuqqdq (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fractuqqdq (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fractuqqdq (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_fractuqqha (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractuqqha (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractuqqha (fxmUQQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractuqqhi (fxmUQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuqqhi (fxmUQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuqqhi (fxmUQQ (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractuqqhq (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractuqqhq (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractuqqhq (fxmUQQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractuqqqi (fxmUQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuqqqi (fxmUQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuqqqi (fxmUQQ (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractuqqqq (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fractuqqqq (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fractuqqqq (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fractuqqsa (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fractuqqsa (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fractuqqsa (fxmUQQ (0x0101010101017f01ULL)))); }
  { f (__gnu_fractuqqsf (fxmUQQ (0x3535353535353535ULL))); }
  { f (__gnu_fractuqqsf (fxmUQQ (0x8181818181818181ULL))); }
  { f (__gnu_fractuqqsf (fxmUQQ (0x0101010101017f01ULL))); }
}
static void fxt25 (void) {
  double wg = 0.0; (void) wg;
  { w ((unsigned long long) __gnu_fractuqqsi (fxmUQQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractuqqsi (fxmUQQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractuqqsi (fxmUQQ (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractuqqsq (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fractuqqsq (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fractuqqsq (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_fractuqquda (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fractuqquda (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fractuqquda (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fractuqqudq2 (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fractuqqudq2 (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fractuqqudq2 (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fractuqquha (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fractuqquha (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fractuqquha (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fractuqquhq2 (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fractuqquhq2 (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fractuqquhq2 (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fractuqqusa (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fractuqqusa (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fractuqqusa (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fractuqqusq2 (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fractuqqusq2 (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fractuqqusq2 (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_fractusada (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fractusada (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fractusada (fxmUSA (0x0101010101017f01ULL)))); }
  { d (__gnu_fractusadf (fxmUSA (0x3535353535353535ULL))); }
  { d (__gnu_fractusadf (fxmUSA (0x8181818181818181ULL))); }
  { d (__gnu_fractusadf (fxmUSA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractusadi (fxmUSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractusadi (fxmUSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractusadi (fxmUSA (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractusadq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fractusadq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fractusadq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_fractusaha (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractusaha (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractusaha (fxmUSA (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractusahi (fxmUSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractusahi (fxmUSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractusahi (fxmUSA (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractusahq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractusahq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractusahq (fxmUSA (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractusaqi (fxmUSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractusaqi (fxmUSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractusaqi (fxmUSA (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractusaqq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fractusaqq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fractusaqq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fractusasa (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fractusasa (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fractusasa (fxmUSA (0x0101010101017f01ULL)))); }
  { f (__gnu_fractusasf (fxmUSA (0x3535353535353535ULL))); }
  { f (__gnu_fractusasf (fxmUSA (0x8181818181818181ULL))); }
  { f (__gnu_fractusasf (fxmUSA (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractusasi (fxmUSA (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractusasi (fxmUSA (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractusasi (fxmUSA (0x0101010101017f01ULL))); }
}
static void fxt26 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbSQ (__gnu_fractusasq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fractusasq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fractusasq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_fractusauda2 (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fractusauda2 (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fractusauda2 (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fractusaudq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fractusaudq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fractusaudq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fractusauha2 (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fractusauha2 (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fractusauha2 (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fractusauhq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fractusauhq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fractusauhq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fractusauqq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fractusauqq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fractusauqq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_fractusausq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_fractusausq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_fractusausq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_fractusqda (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_fractusqda (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_fractusqda (fxmUSQ (0x0101010101017f01ULL)))); }
  { d (__gnu_fractusqdf (fxmUSQ (0x3535353535353535ULL))); }
  { d (__gnu_fractusqdf (fxmUSQ (0x8181818181818181ULL))); }
  { d (__gnu_fractusqdf (fxmUSQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractusqdi (fxmUSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractusqdi (fxmUSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractusqdi (fxmUSQ (0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_fractusqdq (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_fractusqdq (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_fractusqdq (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_fractusqha (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_fractusqha (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_fractusqha (fxmUSQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractusqhi (fxmUSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractusqhi (fxmUSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractusqhi (fxmUSQ (0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_fractusqhq (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_fractusqhq (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_fractusqhq (fxmUSQ (0x0101010101017f01ULL)))); }
  { w ((unsigned long long) __gnu_fractusqqi (fxmUSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractusqqi (fxmUSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractusqqi (fxmUSQ (0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_fractusqqq (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_fractusqqq (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_fractusqqq (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_fractusqsa (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_fractusqsa (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_fractusqsa (fxmUSQ (0x0101010101017f01ULL)))); }
  { f (__gnu_fractusqsf (fxmUSQ (0x3535353535353535ULL))); }
  { f (__gnu_fractusqsf (fxmUSQ (0x8181818181818181ULL))); }
  { f (__gnu_fractusqsf (fxmUSQ (0x0101010101017f01ULL))); }
  { w ((unsigned long long) __gnu_fractusqsi (fxmUSQ (0x3535353535353535ULL))); }
  { w ((unsigned long long) __gnu_fractusqsi (fxmUSQ (0x8181818181818181ULL))); }
  { w ((unsigned long long) __gnu_fractusqsi (fxmUSQ (0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_fractusqsq (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_fractusqsq (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_fractusqsq (fxmUSQ (0x0101010101017f01ULL)))); }
}
static void fxt27 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUDA (__gnu_fractusquda (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_fractusquda (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_fractusquda (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_fractusqudq2 (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_fractusqudq2 (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_fractusqudq2 (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_fractusquha (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_fractusquha (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_fractusquha (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_fractusquhq2 (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_fractusquhq2 (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_fractusquhq2 (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_fractusquqq2 (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_fractusquqq2 (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_fractusquqq2 (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_fractusqusa (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_fractusqusa (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_fractusqusa (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_lshruda3 (fxmUDA (0x3535353535353535ULL), 1))); }
  { w (fxbUDA (__gnu_lshruda3 (fxmUDA (0x8181818181818181ULL), 2))); }
  { w (fxbUDA (__gnu_lshruda3 (fxmUDA (0x0101010101017f01ULL), 3))); }
  { w (fxbUDQ (__gnu_lshrudq3 (fxmUDQ (0x3535353535353535ULL), 1))); }
  { w (fxbUDQ (__gnu_lshrudq3 (fxmUDQ (0x8181818181818181ULL), 2))); }
  { w (fxbUDQ (__gnu_lshrudq3 (fxmUDQ (0x0101010101017f01ULL), 3))); }
  { w (fxbUHA (__gnu_lshruha3 (fxmUHA (0x3535353535353535ULL), 1))); }
  { w (fxbUHA (__gnu_lshruha3 (fxmUHA (0x8181818181818181ULL), 2))); }
  { w (fxbUHA (__gnu_lshruha3 (fxmUHA (0x0101010101017f01ULL), 3))); }
  { w (fxbUHQ (__gnu_lshruhq3 (fxmUHQ (0x3535353535353535ULL), 1))); }
  { w (fxbUHQ (__gnu_lshruhq3 (fxmUHQ (0x8181818181818181ULL), 2))); }
  { w (fxbUHQ (__gnu_lshruhq3 (fxmUHQ (0x0101010101017f01ULL), 3))); }
  { w (fxbUQQ (__gnu_lshruqq3 (fxmUQQ (0x3535353535353535ULL), 1))); }
  { w (fxbUQQ (__gnu_lshruqq3 (fxmUQQ (0x8181818181818181ULL), 2))); }
  { w (fxbUQQ (__gnu_lshruqq3 (fxmUQQ (0x0101010101017f01ULL), 3))); }
  { w (fxbUSA (__gnu_lshrusa3 (fxmUSA (0x3535353535353535ULL), 1))); }
  { w (fxbUSA (__gnu_lshrusa3 (fxmUSA (0x8181818181818181ULL), 2))); }
  { w (fxbUSA (__gnu_lshrusa3 (fxmUSA (0x0101010101017f01ULL), 3))); }
  { w (fxbUSQ (__gnu_lshrusq3 (fxmUSQ (0x3535353535353535ULL), 1))); }
  { w (fxbUSQ (__gnu_lshrusq3 (fxmUSQ (0x8181818181818181ULL), 2))); }
  { w (fxbUSQ (__gnu_lshrusq3 (fxmUSQ (0x0101010101017f01ULL), 3))); }
  { w (fxbDA (__gnu_mulda3 (fxmDA (0x3535353535353535ULL), fxmDA (0x2121212121212121ULL)))); }
  { w (fxbDA (__gnu_mulda3 (fxmDA (0x8181818181818181ULL), fxmDA (0x0303030303030303ULL)))); }
  { w (fxbDA (__gnu_mulda3 (fxmDA (0x0101010101017f01ULL), fxmDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDQ (__gnu_muldq3 (fxmDQ (0x3535353535353535ULL), fxmDQ (0x2121212121212121ULL)))); }
  { w (fxbDQ (__gnu_muldq3 (fxmDQ (0x8181818181818181ULL), fxmDQ (0x0303030303030303ULL)))); }
  { w (fxbDQ (__gnu_muldq3 (fxmDQ (0x0101010101017f01ULL), fxmDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHA (__gnu_mulha3 (fxmHA (0x3535353535353535ULL), fxmHA (0x2121212121212121ULL)))); }
  { w (fxbHA (__gnu_mulha3 (fxmHA (0x8181818181818181ULL), fxmHA (0x0303030303030303ULL)))); }
  { w (fxbHA (__gnu_mulha3 (fxmHA (0x0101010101017f01ULL), fxmHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDA (__gnu_mulhelperda (fxmDA (0x3535353535353535ULL), fxmDA (0x2121212121212121ULL), 0))); }
  { w (fxbDA (__gnu_mulhelperda (fxmDA (0x8181818181818181ULL), fxmDA (0x0303030303030303ULL), 1))); }
  { w (fxbDA (__gnu_mulhelperda (fxmDA (0x0101010101017f01ULL), fxmDA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbDQ (__gnu_mulhelperdq (fxmDQ (0x3535353535353535ULL), fxmDQ (0x2121212121212121ULL), 0))); }
  { w (fxbDQ (__gnu_mulhelperdq (fxmDQ (0x8181818181818181ULL), fxmDQ (0x0303030303030303ULL), 1))); }
  { w (fxbDQ (__gnu_mulhelperdq (fxmDQ (0x0101010101017f01ULL), fxmDQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbHA (__gnu_mulhelperha (fxmHA (0x3535353535353535ULL), fxmHA (0x2121212121212121ULL), 0))); }
  { w (fxbHA (__gnu_mulhelperha (fxmHA (0x8181818181818181ULL), fxmHA (0x0303030303030303ULL), 1))); }
  { w (fxbHA (__gnu_mulhelperha (fxmHA (0x0101010101017f01ULL), fxmHA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbHQ (__gnu_mulhelperhq (fxmHQ (0x3535353535353535ULL), fxmHQ (0x2121212121212121ULL), 0))); }
  { w (fxbHQ (__gnu_mulhelperhq (fxmHQ (0x8181818181818181ULL), fxmHQ (0x0303030303030303ULL), 1))); }
  { w (fxbHQ (__gnu_mulhelperhq (fxmHQ (0x0101010101017f01ULL), fxmHQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
}
static void fxt28 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbQQ (__gnu_mulhelperqq (fxmQQ (0x3535353535353535ULL), fxmQQ (0x2121212121212121ULL), 0))); }
  { w (fxbQQ (__gnu_mulhelperqq (fxmQQ (0x8181818181818181ULL), fxmQQ (0x0303030303030303ULL), 1))); }
  { w (fxbQQ (__gnu_mulhelperqq (fxmQQ (0x0101010101017f01ULL), fxmQQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbSA (__gnu_mulhelpersa (fxmSA (0x3535353535353535ULL), fxmSA (0x2121212121212121ULL), 0))); }
  { w (fxbSA (__gnu_mulhelpersa (fxmSA (0x8181818181818181ULL), fxmSA (0x0303030303030303ULL), 1))); }
  { w (fxbSA (__gnu_mulhelpersa (fxmSA (0x0101010101017f01ULL), fxmSA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbSQ (__gnu_mulhelpersq (fxmSQ (0x3535353535353535ULL), fxmSQ (0x2121212121212121ULL), 0))); }
  { w (fxbSQ (__gnu_mulhelpersq (fxmSQ (0x8181818181818181ULL), fxmSQ (0x0303030303030303ULL), 1))); }
  { w (fxbSQ (__gnu_mulhelpersq (fxmSQ (0x0101010101017f01ULL), fxmSQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUDA (__gnu_mulhelperuda (fxmUDA (0x3535353535353535ULL), fxmUDA (0x2121212121212121ULL), 0))); }
  { w (fxbUDA (__gnu_mulhelperuda (fxmUDA (0x8181818181818181ULL), fxmUDA (0x0303030303030303ULL), 1))); }
  { w (fxbUDA (__gnu_mulhelperuda (fxmUDA (0x0101010101017f01ULL), fxmUDA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUDQ (__gnu_mulhelperudq (fxmUDQ (0x3535353535353535ULL), fxmUDQ (0x2121212121212121ULL), 0))); }
  { w (fxbUDQ (__gnu_mulhelperudq (fxmUDQ (0x8181818181818181ULL), fxmUDQ (0x0303030303030303ULL), 1))); }
  { w (fxbUDQ (__gnu_mulhelperudq (fxmUDQ (0x0101010101017f01ULL), fxmUDQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUHA (__gnu_mulhelperuha (fxmUHA (0x3535353535353535ULL), fxmUHA (0x2121212121212121ULL), 0))); }
  { w (fxbUHA (__gnu_mulhelperuha (fxmUHA (0x8181818181818181ULL), fxmUHA (0x0303030303030303ULL), 1))); }
  { w (fxbUHA (__gnu_mulhelperuha (fxmUHA (0x0101010101017f01ULL), fxmUHA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUHQ (__gnu_mulhelperuhq (fxmUHQ (0x3535353535353535ULL), fxmUHQ (0x2121212121212121ULL), 0))); }
  { w (fxbUHQ (__gnu_mulhelperuhq (fxmUHQ (0x8181818181818181ULL), fxmUHQ (0x0303030303030303ULL), 1))); }
  { w (fxbUHQ (__gnu_mulhelperuhq (fxmUHQ (0x0101010101017f01ULL), fxmUHQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUQQ (__gnu_mulhelperuqq (fxmUQQ (0x3535353535353535ULL), fxmUQQ (0x2121212121212121ULL), 0))); }
  { w (fxbUQQ (__gnu_mulhelperuqq (fxmUQQ (0x8181818181818181ULL), fxmUQQ (0x0303030303030303ULL), 1))); }
  { w (fxbUQQ (__gnu_mulhelperuqq (fxmUQQ (0x0101010101017f01ULL), fxmUQQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUSA (__gnu_mulhelperusa (fxmUSA (0x3535353535353535ULL), fxmUSA (0x2121212121212121ULL), 0))); }
  { w (fxbUSA (__gnu_mulhelperusa (fxmUSA (0x8181818181818181ULL), fxmUSA (0x0303030303030303ULL), 1))); }
  { w (fxbUSA (__gnu_mulhelperusa (fxmUSA (0x0101010101017f01ULL), fxmUSA (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbUSQ (__gnu_mulhelperusq (fxmUSQ (0x3535353535353535ULL), fxmUSQ (0x2121212121212121ULL), 0))); }
  { w (fxbUSQ (__gnu_mulhelperusq (fxmUSQ (0x8181818181818181ULL), fxmUSQ (0x0303030303030303ULL), 1))); }
  { w (fxbUSQ (__gnu_mulhelperusq (fxmUSQ (0x0101010101017f01ULL), fxmUSQ (0xc1c1c1c1c1c1c1c1ULL), 0))); }
  { w (fxbHQ (__gnu_mulhq3 (fxmHQ (0x3535353535353535ULL), fxmHQ (0x2121212121212121ULL)))); }
  { w (fxbHQ (__gnu_mulhq3 (fxmHQ (0x8181818181818181ULL), fxmHQ (0x0303030303030303ULL)))); }
  { w (fxbHQ (__gnu_mulhq3 (fxmHQ (0x0101010101017f01ULL), fxmHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbQQ (__gnu_mulqq3 (fxmQQ (0x3535353535353535ULL), fxmQQ (0x2121212121212121ULL)))); }
  { w (fxbQQ (__gnu_mulqq3 (fxmQQ (0x8181818181818181ULL), fxmQQ (0x0303030303030303ULL)))); }
  { w (fxbQQ (__gnu_mulqq3 (fxmQQ (0x0101010101017f01ULL), fxmQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSA (__gnu_mulsa3 (fxmSA (0x3535353535353535ULL), fxmSA (0x2121212121212121ULL)))); }
  { w (fxbSA (__gnu_mulsa3 (fxmSA (0x8181818181818181ULL), fxmSA (0x0303030303030303ULL)))); }
  { w (fxbSA (__gnu_mulsa3 (fxmSA (0x0101010101017f01ULL), fxmSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSQ (__gnu_mulsq3 (fxmSQ (0x3535353535353535ULL), fxmSQ (0x2121212121212121ULL)))); }
  { w (fxbSQ (__gnu_mulsq3 (fxmSQ (0x8181818181818181ULL), fxmSQ (0x0303030303030303ULL)))); }
  { w (fxbSQ (__gnu_mulsq3 (fxmSQ (0x0101010101017f01ULL), fxmSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDA (__gnu_muluda3 (fxmUDA (0x3535353535353535ULL), fxmUDA (0x2121212121212121ULL)))); }
  { w (fxbUDA (__gnu_muluda3 (fxmUDA (0x8181818181818181ULL), fxmUDA (0x0303030303030303ULL)))); }
  { w (fxbUDA (__gnu_muluda3 (fxmUDA (0x0101010101017f01ULL), fxmUDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDQ (__gnu_muludq3 (fxmUDQ (0x3535353535353535ULL), fxmUDQ (0x2121212121212121ULL)))); }
  { w (fxbUDQ (__gnu_muludq3 (fxmUDQ (0x8181818181818181ULL), fxmUDQ (0x0303030303030303ULL)))); }
  { w (fxbUDQ (__gnu_muludq3 (fxmUDQ (0x0101010101017f01ULL), fxmUDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHA (__gnu_muluha3 (fxmUHA (0x3535353535353535ULL), fxmUHA (0x2121212121212121ULL)))); }
  { w (fxbUHA (__gnu_muluha3 (fxmUHA (0x8181818181818181ULL), fxmUHA (0x0303030303030303ULL)))); }
  { w (fxbUHA (__gnu_muluha3 (fxmUHA (0x0101010101017f01ULL), fxmUHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHQ (__gnu_muluhq3 (fxmUHQ (0x3535353535353535ULL), fxmUHQ (0x2121212121212121ULL)))); }
  { w (fxbUHQ (__gnu_muluhq3 (fxmUHQ (0x8181818181818181ULL), fxmUHQ (0x0303030303030303ULL)))); }
  { w (fxbUHQ (__gnu_muluhq3 (fxmUHQ (0x0101010101017f01ULL), fxmUHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUQQ (__gnu_muluqq3 (fxmUQQ (0x3535353535353535ULL), fxmUQQ (0x2121212121212121ULL)))); }
  { w (fxbUQQ (__gnu_muluqq3 (fxmUQQ (0x8181818181818181ULL), fxmUQQ (0x0303030303030303ULL)))); }
  { w (fxbUQQ (__gnu_muluqq3 (fxmUQQ (0x0101010101017f01ULL), fxmUQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSA (__gnu_mulusa3 (fxmUSA (0x3535353535353535ULL), fxmUSA (0x2121212121212121ULL)))); }
  { w (fxbUSA (__gnu_mulusa3 (fxmUSA (0x8181818181818181ULL), fxmUSA (0x0303030303030303ULL)))); }
  { w (fxbUSA (__gnu_mulusa3 (fxmUSA (0x0101010101017f01ULL), fxmUSA (0xc1c1c1c1c1c1c1c1ULL)))); }
}
static void fxt29 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUSQ (__gnu_mulusq3 (fxmUSQ (0x3535353535353535ULL), fxmUSQ (0x2121212121212121ULL)))); }
  { w (fxbUSQ (__gnu_mulusq3 (fxmUSQ (0x8181818181818181ULL), fxmUSQ (0x0303030303030303ULL)))); }
  { w (fxbUSQ (__gnu_mulusq3 (fxmUSQ (0x0101010101017f01ULL), fxmUSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDA (__gnu_negda2 (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_negda2 (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_negda2 (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_negdq2 (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_negdq2 (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_negdq2 (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_negha2 (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_negha2 (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_negha2 (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_neghq2 (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_neghq2 (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_neghq2 (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_negqq2 (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_negqq2 (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_negqq2 (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_negsa2 (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_negsa2 (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_negsa2 (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_negsq2 (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_negsq2 (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_negsq2 (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_neguda2 (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_neguda2 (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_neguda2 (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_negudq2 (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_negudq2 (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_negudq2 (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_neguha2 (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_neguha2 (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_neguha2 (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_neguhq2 (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_neguhq2 (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_neguhq2 (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_neguqq2 (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_neguqq2 (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_neguqq2 (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_negusa2 (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_negusa2 (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_negusa2 (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_negusq2 (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_negusq2 (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_negusq2 (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfractdadq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfractdadq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfractdadq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfractdaha2 (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractdaha2 (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractdaha2 (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfractdahq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractdahq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractdahq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_satfractdaqq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfractdaqq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfractdaqq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_satfractdasa2 (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfractdasa2 (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfractdasa2 (fxmDA (0x0101010101017f01ULL)))); }
}
static void fxt30 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbSQ (__gnu_satfractdasq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfractdasq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfractdasq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfractdauda (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfractdauda (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfractdauda (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfractdaudq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfractdaudq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfractdaudq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfractdauha (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfractdauha (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfractdauha (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfractdauhq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfractdauhq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfractdauhq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfractdauqq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfractdauqq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfractdauqq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_satfractdausa (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfractdausa (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfractdausa (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfractdausq (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfractdausq (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfractdausq (fxmDA (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfractdfda (0.3))); }
  { w (fxbDA (__gnu_satfractdfda (0.0625))); }
  { w (fxbDA (__gnu_satfractdfda (0.4375))); }
  { w (fxbDQ (__gnu_satfractdfdq (0.3))); }
  { w (fxbDQ (__gnu_satfractdfdq (0.0625))); }
  { w (fxbDQ (__gnu_satfractdfdq (0.4375))); }
  { w (fxbHA (__gnu_satfractdfha (0.3))); }
  { w (fxbHA (__gnu_satfractdfha (0.0625))); }
  { w (fxbHA (__gnu_satfractdfha (0.4375))); }
  { w (fxbHQ (__gnu_satfractdfhq (0.3))); }
  { w (fxbHQ (__gnu_satfractdfhq (0.0625))); }
  { w (fxbHQ (__gnu_satfractdfhq (0.4375))); }
  { w (fxbQQ (__gnu_satfractdfqq (0.3))); }
  { w (fxbQQ (__gnu_satfractdfqq (0.0625))); }
  { w (fxbQQ (__gnu_satfractdfqq (0.4375))); }
  { w (fxbSA (__gnu_satfractdfsa (0.3))); }
  { w (fxbSA (__gnu_satfractdfsa (0.0625))); }
  { w (fxbSA (__gnu_satfractdfsa (0.4375))); }
  { w (fxbSQ (__gnu_satfractdfsq (0.3))); }
  { w (fxbSQ (__gnu_satfractdfsq (0.0625))); }
  { w (fxbSQ (__gnu_satfractdfsq (0.4375))); }
  { w (fxbUDA (__gnu_satfractdfuda (0.3))); }
  { w (fxbUDA (__gnu_satfractdfuda (0.0625))); }
  { w (fxbUDA (__gnu_satfractdfuda (0.4375))); }
  { w (fxbUDQ (__gnu_satfractdfudq (0.3))); }
  { w (fxbUDQ (__gnu_satfractdfudq (0.0625))); }
  { w (fxbUDQ (__gnu_satfractdfudq (0.4375))); }
  { w (fxbUHA (__gnu_satfractdfuha (0.3))); }
  { w (fxbUHA (__gnu_satfractdfuha (0.0625))); }
  { w (fxbUHA (__gnu_satfractdfuha (0.4375))); }
  { w (fxbUHQ (__gnu_satfractdfuhq (0.3))); }
  { w (fxbUHQ (__gnu_satfractdfuhq (0.0625))); }
  { w (fxbUHQ (__gnu_satfractdfuhq (0.4375))); }
  { w (fxbUQQ (__gnu_satfractdfuqq (0.3))); }
  { w (fxbUQQ (__gnu_satfractdfuqq (0.0625))); }
  { w (fxbUQQ (__gnu_satfractdfuqq (0.4375))); }
}
static void fxt31 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUSA (__gnu_satfractdfusa (0.3))); }
  { w (fxbUSA (__gnu_satfractdfusa (0.0625))); }
  { w (fxbUSA (__gnu_satfractdfusa (0.4375))); }
  { w (fxbUSQ (__gnu_satfractdfusq (0.3))); }
  { w (fxbUSQ (__gnu_satfractdfusq (0.0625))); }
  { w (fxbUSQ (__gnu_satfractdfusq (0.4375))); }
  { w (fxbDA (__gnu_satfractdida ((DItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_satfractdida ((DItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_satfractdida ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_satfractdidq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_satfractdidq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_satfractdidq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_satfractdiha ((DItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_satfractdiha ((DItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_satfractdiha ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_satfractdihq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_satfractdihq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_satfractdihq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_satfractdiqq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_satfractdiqq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_satfractdiqq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_satfractdisa ((DItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_satfractdisa ((DItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_satfractdisa ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_satfractdisq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_satfractdisq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_satfractdisq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_satfractdiuda ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_satfractdiuda ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_satfractdiuda ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_satfractdiudq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_satfractdiudq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_satfractdiudq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_satfractdiuha ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_satfractdiuha ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_satfractdiuha ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_satfractdiuhq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_satfractdiuhq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_satfractdiuhq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_satfractdiuqq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_satfractdiuqq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_satfractdiuqq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_satfractdiusa ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_satfractdiusa ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_satfractdiusa ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_satfractdiusq ((DItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_satfractdiusq ((DItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_satfractdiusq ((DItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_satfractdqda (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfractdqda (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfractdqda (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfractdqha (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractdqha (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractdqha (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfractdqhq2 (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractdqhq2 (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractdqhq2 (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_satfractdqqq2 (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfractdqqq2 (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfractdqqq2 (fxmDQ (0x0101010101017f01ULL)))); }
}
static void fxt32 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbSA (__gnu_satfractdqsa (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfractdqsa (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfractdqsa (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfractdqsq2 (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfractdqsq2 (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfractdqsq2 (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfractdquda (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfractdquda (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfractdquda (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfractdqudq (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfractdqudq (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfractdqudq (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfractdquha (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfractdquha (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfractdquha (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfractdquhq (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfractdquhq (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfractdquhq (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfractdquqq (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfractdquqq (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfractdquqq (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_satfractdqusa (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfractdqusa (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfractdqusa (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfractdqusq (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfractdqusq (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfractdqusq (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfracthada2 (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfracthada2 (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfracthada2 (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfracthadq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfracthadq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfracthadq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfracthahq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfracthahq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfracthahq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_satfracthaqq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfracthaqq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfracthaqq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_satfracthasa2 (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfracthasa2 (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfracthasa2 (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfracthasq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfracthasq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfracthasq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfracthauda (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfracthauda (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfracthauda (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfracthaudq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfracthaudq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfracthaudq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfracthauha (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfracthauha (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfracthauha (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfracthauhq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfracthauhq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfracthauhq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfracthauqq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfracthauqq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfracthauqq (fxmHA (0x0101010101017f01ULL)))); }
}
static void fxt33 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUSA (__gnu_satfracthausa (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfracthausa (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfracthausa (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfracthausq (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfracthausq (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfracthausq (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfracthida ((HItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_satfracthida ((HItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_satfracthida ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_satfracthidq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_satfracthidq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_satfracthidq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_satfracthiha ((HItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_satfracthiha ((HItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_satfracthiha ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_satfracthihq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_satfracthihq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_satfracthihq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_satfracthiqq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_satfracthiqq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_satfracthiqq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_satfracthisa ((HItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_satfracthisa ((HItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_satfracthisa ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_satfracthisq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_satfracthisq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_satfracthisq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_satfracthiuda ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_satfracthiuda ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_satfracthiuda ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_satfracthiudq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_satfracthiudq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_satfracthiudq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_satfracthiuha ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_satfracthiuha ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_satfracthiuha ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_satfracthiuhq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_satfracthiuhq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_satfracthiuhq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_satfracthiuqq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_satfracthiuqq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_satfracthiuqq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_satfracthiusa ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_satfracthiusa ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_satfracthiusa ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_satfracthiusq ((HItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_satfracthiusq ((HItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_satfracthiusq ((HItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_satfracthqda (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfracthqda (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfracthqda (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfracthqdq2 (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfracthqdq2 (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfracthqdq2 (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfracthqha (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfracthqha (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfracthqha (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_satfracthqqq2 (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfracthqqq2 (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfracthqqq2 (fxmHQ (0x0101010101017f01ULL)))); }
}
static void fxt34 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbSA (__gnu_satfracthqsa (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfracthqsa (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfracthqsa (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfracthqsq2 (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfracthqsq2 (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfracthqsq2 (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfracthquda (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfracthquda (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfracthquda (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfracthqudq (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfracthqudq (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfracthqudq (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfracthquha (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfracthquha (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfracthquha (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfracthquhq (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfracthquhq (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfracthquhq (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfracthquqq (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfracthquqq (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfracthquqq (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_satfracthqusa (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfracthqusa (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfracthqusa (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfracthqusq (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfracthqusq (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfracthqusq (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfractqida ((QItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_satfractqida ((QItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_satfractqida ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_satfractqidq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_satfractqidq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_satfractqidq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_satfractqiha ((QItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_satfractqiha ((QItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_satfractqiha ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_satfractqihq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_satfractqihq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_satfractqihq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_satfractqiqq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_satfractqiqq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_satfractqiqq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_satfractqisa ((QItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_satfractqisa ((QItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_satfractqisa ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_satfractqisq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_satfractqisq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_satfractqisq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_satfractqiuda ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_satfractqiuda ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_satfractqiuda ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_satfractqiudq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_satfractqiudq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_satfractqiudq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_satfractqiuha ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_satfractqiuha ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_satfractqiuha ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_satfractqiuhq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_satfractqiuhq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_satfractqiuhq ((QItype) 0x0101010101017f01ULL))); }
}
static void fxt35 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUQQ (__gnu_satfractqiuqq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_satfractqiuqq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_satfractqiuqq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_satfractqiusa ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_satfractqiusa ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_satfractqiusa ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_satfractqiusq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_satfractqiusq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_satfractqiusq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_satfractqqda (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfractqqda (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfractqqda (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfractqqdq2 (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfractqqdq2 (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfractqqdq2 (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfractqqha (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractqqha (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractqqha (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfractqqhq2 (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractqqhq2 (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractqqhq2 (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_satfractqqsa (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfractqqsa (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfractqqsa (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfractqqsq2 (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfractqqsq2 (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfractqqsq2 (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfractqquda (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfractqquda (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfractqquda (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfractqqudq (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfractqqudq (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfractqqudq (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfractqquha (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfractqquha (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfractqquha (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfractqquhq (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfractqquhq (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfractqquhq (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfractqquqq (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfractqquqq (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfractqquqq (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_satfractqqusa (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfractqqusa (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfractqqusa (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfractqqusq (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfractqqusq (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfractqqusq (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfractsada2 (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfractsada2 (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfractsada2 (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfractsadq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfractsadq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfractsadq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfractsaha2 (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractsaha2 (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractsaha2 (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfractsahq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractsahq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractsahq (fxmSA (0x0101010101017f01ULL)))); }
}
static void fxt36 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbQQ (__gnu_satfractsaqq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfractsaqq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfractsaqq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfractsasq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfractsasq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfractsasq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfractsauda (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfractsauda (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfractsauda (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfractsaudq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfractsaudq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfractsaudq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfractsauha (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfractsauha (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfractsauha (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfractsauhq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfractsauhq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfractsauhq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfractsauqq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfractsauqq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfractsauqq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_satfractsausa (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfractsausa (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfractsausa (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfractsausq (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfractsausq (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfractsausq (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfractsfda (0.3f))); }
  { w (fxbDA (__gnu_satfractsfda (0.0625f))); }
  { w (fxbDA (__gnu_satfractsfda (0.4375f))); }
  { w (fxbDQ (__gnu_satfractsfdq (0.3f))); }
  { w (fxbDQ (__gnu_satfractsfdq (0.0625f))); }
  { w (fxbDQ (__gnu_satfractsfdq (0.4375f))); }
  { w (fxbHA (__gnu_satfractsfha (0.3f))); }
  { w (fxbHA (__gnu_satfractsfha (0.0625f))); }
  { w (fxbHA (__gnu_satfractsfha (0.4375f))); }
  { w (fxbHQ (__gnu_satfractsfhq (0.3f))); }
  { w (fxbHQ (__gnu_satfractsfhq (0.0625f))); }
  { w (fxbHQ (__gnu_satfractsfhq (0.4375f))); }
  { w (fxbQQ (__gnu_satfractsfqq (0.3f))); }
  { w (fxbQQ (__gnu_satfractsfqq (0.0625f))); }
  { w (fxbQQ (__gnu_satfractsfqq (0.4375f))); }
  { w (fxbSA (__gnu_satfractsfsa (0.3f))); }
  { w (fxbSA (__gnu_satfractsfsa (0.0625f))); }
  { w (fxbSA (__gnu_satfractsfsa (0.4375f))); }
  { w (fxbSQ (__gnu_satfractsfsq (0.3f))); }
  { w (fxbSQ (__gnu_satfractsfsq (0.0625f))); }
  { w (fxbSQ (__gnu_satfractsfsq (0.4375f))); }
  { w (fxbUDA (__gnu_satfractsfuda (0.3f))); }
  { w (fxbUDA (__gnu_satfractsfuda (0.0625f))); }
  { w (fxbUDA (__gnu_satfractsfuda (0.4375f))); }
  { w (fxbUDQ (__gnu_satfractsfudq (0.3f))); }
  { w (fxbUDQ (__gnu_satfractsfudq (0.0625f))); }
  { w (fxbUDQ (__gnu_satfractsfudq (0.4375f))); }
  { w (fxbUHA (__gnu_satfractsfuha (0.3f))); }
  { w (fxbUHA (__gnu_satfractsfuha (0.0625f))); }
  { w (fxbUHA (__gnu_satfractsfuha (0.4375f))); }
  { w (fxbUHQ (__gnu_satfractsfuhq (0.3f))); }
  { w (fxbUHQ (__gnu_satfractsfuhq (0.0625f))); }
  { w (fxbUHQ (__gnu_satfractsfuhq (0.4375f))); }
}
static void fxt37 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUQQ (__gnu_satfractsfuqq (0.3f))); }
  { w (fxbUQQ (__gnu_satfractsfuqq (0.0625f))); }
  { w (fxbUQQ (__gnu_satfractsfuqq (0.4375f))); }
  { w (fxbUSA (__gnu_satfractsfusa (0.3f))); }
  { w (fxbUSA (__gnu_satfractsfusa (0.0625f))); }
  { w (fxbUSA (__gnu_satfractsfusa (0.4375f))); }
  { w (fxbUSQ (__gnu_satfractsfusq (0.3f))); }
  { w (fxbUSQ (__gnu_satfractsfusq (0.0625f))); }
  { w (fxbUSQ (__gnu_satfractsfusq (0.4375f))); }
  { w (fxbDA (__gnu_satfractsida ((SItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_satfractsida ((SItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_satfractsida ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_satfractsidq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_satfractsidq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_satfractsidq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_satfractsiha ((SItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_satfractsiha ((SItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_satfractsiha ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_satfractsihq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_satfractsihq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_satfractsihq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_satfractsiqq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_satfractsiqq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_satfractsiqq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_satfractsisa ((SItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_satfractsisa ((SItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_satfractsisa ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_satfractsisq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_satfractsisq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_satfractsisq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_satfractsiuda ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_satfractsiuda ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_satfractsiuda ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_satfractsiudq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_satfractsiudq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_satfractsiudq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_satfractsiuha ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_satfractsiuha ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_satfractsiuha ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_satfractsiuhq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_satfractsiuhq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_satfractsiuhq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_satfractsiuqq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_satfractsiuqq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_satfractsiuqq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_satfractsiusa ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_satfractsiusa ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_satfractsiusa ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_satfractsiusq ((SItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_satfractsiusq ((SItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_satfractsiusq ((SItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_satfractsqda (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfractsqda (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfractsqda (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfractsqdq2 (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfractsqdq2 (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfractsqdq2 (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfractsqha (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractsqha (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractsqha (fxmSQ (0x0101010101017f01ULL)))); }
}
static void fxt38 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbHQ (__gnu_satfractsqhq2 (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractsqhq2 (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractsqhq2 (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_satfractsqqq2 (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfractsqqq2 (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfractsqqq2 (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_satfractsqsa (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfractsqsa (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfractsqsa (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfractsquda (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfractsquda (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfractsquda (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfractsqudq (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfractsqudq (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfractsqudq (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfractsquha (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfractsquha (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfractsquha (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfractsquhq (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfractsquhq (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfractsquhq (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfractsquqq (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfractsquqq (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfractsquqq (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_satfractsqusa (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfractsqusa (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfractsqusa (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfractsqusq (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfractsqusq (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfractsqusq (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfractudada (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfractudada (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfractudada (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfractudadq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfractudadq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfractudadq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfractudaha (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractudaha (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractudaha (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfractudahq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractudahq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractudahq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_satfractudaqq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfractudaqq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfractudaqq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_satfractudasa (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfractudasa (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfractudasa (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfractudasq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfractudasq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfractudasq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfractudaudq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfractudaudq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfractudaudq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfractudauha2 (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfractudauha2 (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfractudauha2 (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfractudauhq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfractudauhq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfractudauhq (fxmUDA (0x0101010101017f01ULL)))); }
}
static void fxt39 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUQQ (__gnu_satfractudauqq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfractudauqq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfractudauqq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_satfractudausa2 (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfractudausa2 (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfractudausa2 (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfractudausq (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfractudausq (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfractudausq (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfractudqda (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfractudqda (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfractudqda (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfractudqdq (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfractudqdq (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfractudqdq (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfractudqha (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractudqha (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractudqha (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfractudqhq (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractudqhq (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractudqhq (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_satfractudqqq (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfractudqqq (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfractudqqq (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_satfractudqsa (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfractudqsa (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfractudqsa (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfractudqsq (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfractudqsq (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfractudqsq (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfractudquda (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfractudquda (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfractudquda (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfractudquha (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfractudquha (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfractudquha (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfractudquhq2 (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfractudquhq2 (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfractudquhq2 (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfractudquqq2 (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfractudquqq2 (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfractudquqq2 (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_satfractudqusa (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfractudqusa (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfractudqusa (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfractudqusq2 (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfractudqusq2 (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfractudqusq2 (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfractuhada (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfractuhada (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfractuhada (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfractuhadq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfractuhadq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfractuhadq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfractuhaha (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractuhaha (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractuhaha (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfractuhahq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractuhahq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractuhahq (fxmUHA (0x0101010101017f01ULL)))); }
}
static void fxt40 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbQQ (__gnu_satfractuhaqq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfractuhaqq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfractuhaqq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_satfractuhasa (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfractuhasa (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfractuhasa (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfractuhasq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfractuhasq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfractuhasq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfractuhauda2 (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfractuhauda2 (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfractuhauda2 (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfractuhaudq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfractuhaudq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfractuhaudq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfractuhauhq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfractuhauhq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfractuhauhq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfractuhauqq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfractuhauqq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfractuhauqq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_satfractuhausa2 (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfractuhausa2 (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfractuhausa2 (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfractuhausq (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfractuhausq (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfractuhausq (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfractuhqda (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfractuhqda (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfractuhqda (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfractuhqdq (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfractuhqdq (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfractuhqdq (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfractuhqha (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractuhqha (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractuhqha (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfractuhqhq (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractuhqhq (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractuhqhq (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_satfractuhqqq (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfractuhqqq (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfractuhqqq (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_satfractuhqsa (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfractuhqsa (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfractuhqsa (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfractuhqsq (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfractuhqsq (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfractuhqsq (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfractuhquda (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfractuhquda (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfractuhquda (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfractuhqudq2 (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfractuhqudq2 (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfractuhqudq2 (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfractuhquha (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfractuhquha (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfractuhquha (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfractuhquqq2 (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfractuhquqq2 (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfractuhquqq2 (fxmUHQ (0x0101010101017f01ULL)))); }
}
static void fxt41 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUSA (__gnu_satfractuhqusa (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfractuhqusa (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfractuhqusa (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfractuhqusq2 (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfractuhqusq2 (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfractuhqusq2 (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfractunsdida ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_satfractunsdida ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_satfractunsdida ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_satfractunsdidq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_satfractunsdidq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_satfractunsdidq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_satfractunsdiha ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_satfractunsdiha ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_satfractunsdiha ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_satfractunsdihq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_satfractunsdihq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_satfractunsdihq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_satfractunsdiqq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_satfractunsdiqq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_satfractunsdiqq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_satfractunsdisa ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_satfractunsdisa ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_satfractunsdisa ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_satfractunsdisq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_satfractunsdisq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_satfractunsdisq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_satfractunsdiuda ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_satfractunsdiuda ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_satfractunsdiuda ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_satfractunsdiudq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_satfractunsdiudq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_satfractunsdiudq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_satfractunsdiuha ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_satfractunsdiuha ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_satfractunsdiuha ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_satfractunsdiuhq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_satfractunsdiuhq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_satfractunsdiuhq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_satfractunsdiuqq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_satfractunsdiuqq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_satfractunsdiuqq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_satfractunsdiusa ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_satfractunsdiusa ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_satfractunsdiusa ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_satfractunsdiusq ((UDItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_satfractunsdiusq ((UDItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_satfractunsdiusq ((UDItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_satfractunshida ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_satfractunshida ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_satfractunshida ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_satfractunshidq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_satfractunshidq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_satfractunshidq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_satfractunshiha ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_satfractunshiha ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_satfractunshiha ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_satfractunshihq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_satfractunshihq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_satfractunshihq ((UHItype) 0x0101010101017f01ULL))); }
}
static void fxt42 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbQQ (__gnu_satfractunshiqq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_satfractunshiqq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_satfractunshiqq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_satfractunshisa ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_satfractunshisa ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_satfractunshisa ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_satfractunshisq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_satfractunshisq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_satfractunshisq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_satfractunshiuda ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_satfractunshiuda ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_satfractunshiuda ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_satfractunshiudq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_satfractunshiudq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_satfractunshiudq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_satfractunshiuha ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_satfractunshiuha ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_satfractunshiuha ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_satfractunshiuhq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_satfractunshiuhq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_satfractunshiuhq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_satfractunshiuqq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_satfractunshiuqq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_satfractunshiuqq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_satfractunshiusa ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_satfractunshiusa ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_satfractunshiusa ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_satfractunshiusq ((UHItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_satfractunshiusq ((UHItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_satfractunshiusq ((UHItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_satfractunsqida ((QItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_satfractunsqida ((QItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_satfractunsqida ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_satfractunsqidq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_satfractunsqidq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_satfractunsqidq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_satfractunsqiha ((QItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_satfractunsqiha ((QItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_satfractunsqiha ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_satfractunsqihq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_satfractunsqihq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_satfractunsqihq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_satfractunsqiqq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_satfractunsqiqq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_satfractunsqiqq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_satfractunsqisa ((QItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_satfractunsqisa ((QItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_satfractunsqisa ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_satfractunsqisq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_satfractunsqisq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_satfractunsqisq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_satfractunsqiuda ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_satfractunsqiuda ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_satfractunsqiuda ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_satfractunsqiudq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_satfractunsqiudq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_satfractunsqiudq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_satfractunsqiuha ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_satfractunsqiuha ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_satfractunsqiuha ((QItype) 0x0101010101017f01ULL))); }
}
static void fxt43 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUHQ (__gnu_satfractunsqiuhq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_satfractunsqiuhq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_satfractunsqiuhq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_satfractunsqiuqq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_satfractunsqiuqq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_satfractunsqiuqq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_satfractunsqiusa ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_satfractunsqiusa ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_satfractunsqiusa ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_satfractunsqiusq ((QItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_satfractunsqiusq ((QItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_satfractunsqiusq ((QItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_satfractunssida ((USItype) 0x3535353535353535ULL))); }
  { w (fxbDA (__gnu_satfractunssida ((USItype) 0x8181818181818181ULL))); }
  { w (fxbDA (__gnu_satfractunssida ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbDQ (__gnu_satfractunssidq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbDQ (__gnu_satfractunssidq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbDQ (__gnu_satfractunssidq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbHA (__gnu_satfractunssiha ((USItype) 0x3535353535353535ULL))); }
  { w (fxbHA (__gnu_satfractunssiha ((USItype) 0x8181818181818181ULL))); }
  { w (fxbHA (__gnu_satfractunssiha ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbHQ (__gnu_satfractunssihq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbHQ (__gnu_satfractunssihq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbHQ (__gnu_satfractunssihq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbQQ (__gnu_satfractunssiqq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbQQ (__gnu_satfractunssiqq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbQQ (__gnu_satfractunssiqq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbSA (__gnu_satfractunssisa ((USItype) 0x3535353535353535ULL))); }
  { w (fxbSA (__gnu_satfractunssisa ((USItype) 0x8181818181818181ULL))); }
  { w (fxbSA (__gnu_satfractunssisa ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbSQ (__gnu_satfractunssisq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbSQ (__gnu_satfractunssisq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbSQ (__gnu_satfractunssisq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUDA (__gnu_satfractunssiuda ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUDA (__gnu_satfractunssiuda ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUDA (__gnu_satfractunssiuda ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUDQ (__gnu_satfractunssiudq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUDQ (__gnu_satfractunssiudq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUDQ (__gnu_satfractunssiudq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUHA (__gnu_satfractunssiuha ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUHA (__gnu_satfractunssiuha ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUHA (__gnu_satfractunssiuha ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUHQ (__gnu_satfractunssiuhq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUHQ (__gnu_satfractunssiuhq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUHQ (__gnu_satfractunssiuhq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUQQ (__gnu_satfractunssiuqq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUQQ (__gnu_satfractunssiuqq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUQQ (__gnu_satfractunssiuqq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUSA (__gnu_satfractunssiusa ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUSA (__gnu_satfractunssiusa ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUSA (__gnu_satfractunssiusa ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbUSQ (__gnu_satfractunssiusq ((USItype) 0x3535353535353535ULL))); }
  { w (fxbUSQ (__gnu_satfractunssiusq ((USItype) 0x8181818181818181ULL))); }
  { w (fxbUSQ (__gnu_satfractunssiusq ((USItype) 0x0101010101017f01ULL))); }
  { w (fxbDA (__gnu_satfractuqqda (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfractuqqda (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfractuqqda (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfractuqqdq (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfractuqqdq (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfractuqqdq (fxmUQQ (0x0101010101017f01ULL)))); }
}
static void fxt44 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbHA (__gnu_satfractuqqha (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractuqqha (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractuqqha (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfractuqqhq (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractuqqhq (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractuqqhq (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_satfractuqqqq (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfractuqqqq (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfractuqqqq (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_satfractuqqsa (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfractuqqsa (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfractuqqsa (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfractuqqsq (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfractuqqsq (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfractuqqsq (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfractuqquda (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfractuqquda (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfractuqquda (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfractuqqudq2 (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfractuqqudq2 (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfractuqqudq2 (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfractuqquha (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfractuqquha (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfractuqquha (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfractuqquhq2 (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfractuqquhq2 (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfractuqquhq2 (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_satfractuqqusa (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfractuqqusa (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfractuqqusa (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfractuqqusq2 (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfractuqqusq2 (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfractuqqusq2 (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfractusada (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfractusada (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfractusada (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfractusadq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfractusadq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfractusadq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfractusaha (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractusaha (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractusaha (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfractusahq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractusahq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractusahq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_satfractusaqq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfractusaqq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfractusaqq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_satfractusasa (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfractusasa (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfractusasa (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfractusasq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfractusasq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfractusasq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfractusauda2 (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfractusauda2 (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfractusauda2 (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfractusaudq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfractusaudq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfractusaudq (fxmUSA (0x0101010101017f01ULL)))); }
}
static void fxt45 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUHA (__gnu_satfractusauha2 (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfractusauha2 (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfractusauha2 (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfractusauhq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfractusauhq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfractusauhq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfractusauqq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfractusauqq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfractusauqq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_satfractusausq (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_satfractusausq (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_satfractusausq (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_satfractusqda (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_satfractusqda (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_satfractusqda (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbDQ (__gnu_satfractusqdq (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_satfractusqdq (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_satfractusqdq (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_satfractusqha (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_satfractusqha (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_satfractusqha (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_satfractusqhq (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_satfractusqhq (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_satfractusqhq (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_satfractusqqq (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_satfractusqqq (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_satfractusqqq (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_satfractusqsa (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_satfractusqsa (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_satfractusqsa (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_satfractusqsq (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_satfractusqsq (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_satfractusqsq (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_satfractusquda (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_satfractusquda (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_satfractusquda (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_satfractusqudq2 (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_satfractusqudq2 (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_satfractusqudq2 (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_satfractusquha (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_satfractusquha (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_satfractusquha (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_satfractusquhq2 (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_satfractusquhq2 (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_satfractusquhq2 (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_satfractusquqq2 (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_satfractusquqq2 (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_satfractusquqq2 (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_satfractusqusa (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_satfractusqusa (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_satfractusqusa (fxmUSQ (0x0101010101017f01ULL)))); }
  { SItype x0 = (SItype) 0x3535353535353535ULL; __gnu_saturate1ha (&x0); w ((unsigned long long) x0); }
  { SItype x0 = (SItype) 0x8181818181818181ULL; __gnu_saturate1ha (&x0); w ((unsigned long long) x0); }
  { SItype x0 = (SItype) 0x0101010101017f01ULL; __gnu_saturate1ha (&x0); w ((unsigned long long) x0); }
  { SItype x0 = (SItype) 0x3535353535353535ULL; __gnu_saturate1hq (&x0); w ((unsigned long long) x0); }
  { SItype x0 = (SItype) 0x8181818181818181ULL; __gnu_saturate1hq (&x0); w ((unsigned long long) x0); }
  { SItype x0 = (SItype) 0x0101010101017f01ULL; __gnu_saturate1hq (&x0); w ((unsigned long long) x0); }
  { HItype x0 = (HItype) 0x3535353535353535ULL; __gnu_saturate1qq (&x0); w ((unsigned long long) x0); }
  { HItype x0 = (HItype) 0x8181818181818181ULL; __gnu_saturate1qq (&x0); w ((unsigned long long) x0); }
  { HItype x0 = (HItype) 0x0101010101017f01ULL; __gnu_saturate1qq (&x0); w ((unsigned long long) x0); }
}
static void fxt46 (void) {
  double wg = 0.0; (void) wg;
  { DItype x0 = (DItype) 0x3535353535353535ULL; __gnu_saturate1sa (&x0); w ((unsigned long long) x0); }
  { DItype x0 = (DItype) 0x8181818181818181ULL; __gnu_saturate1sa (&x0); w ((unsigned long long) x0); }
  { DItype x0 = (DItype) 0x0101010101017f01ULL; __gnu_saturate1sa (&x0); w ((unsigned long long) x0); }
  { DItype x0 = (DItype) 0x3535353535353535ULL; __gnu_saturate1sq (&x0); w ((unsigned long long) x0); }
  { DItype x0 = (DItype) 0x8181818181818181ULL; __gnu_saturate1sq (&x0); w ((unsigned long long) x0); }
  { DItype x0 = (DItype) 0x0101010101017f01ULL; __gnu_saturate1sq (&x0); w ((unsigned long long) x0); }
  { USItype x0 = (USItype) 0x3535353535353535ULL; __gnu_saturate1uha (&x0); w ((unsigned long long) x0); }
  { USItype x0 = (USItype) 0x8181818181818181ULL; __gnu_saturate1uha (&x0); w ((unsigned long long) x0); }
  { USItype x0 = (USItype) 0x0101010101017f01ULL; __gnu_saturate1uha (&x0); w ((unsigned long long) x0); }
  { USItype x0 = (USItype) 0x3535353535353535ULL; __gnu_saturate1uhq (&x0); w ((unsigned long long) x0); }
  { USItype x0 = (USItype) 0x8181818181818181ULL; __gnu_saturate1uhq (&x0); w ((unsigned long long) x0); }
  { USItype x0 = (USItype) 0x0101010101017f01ULL; __gnu_saturate1uhq (&x0); w ((unsigned long long) x0); }
  { UHItype x0 = (UHItype) 0x3535353535353535ULL; __gnu_saturate1uqq (&x0); w ((unsigned long long) x0); }
  { UHItype x0 = (UHItype) 0x8181818181818181ULL; __gnu_saturate1uqq (&x0); w ((unsigned long long) x0); }
  { UHItype x0 = (UHItype) 0x0101010101017f01ULL; __gnu_saturate1uqq (&x0); w ((unsigned long long) x0); }
  { UDItype x0 = (UDItype) 0x3535353535353535ULL; __gnu_saturate1usa (&x0); w ((unsigned long long) x0); }
  { UDItype x0 = (UDItype) 0x8181818181818181ULL; __gnu_saturate1usa (&x0); w ((unsigned long long) x0); }
  { UDItype x0 = (UDItype) 0x0101010101017f01ULL; __gnu_saturate1usa (&x0); w ((unsigned long long) x0); }
  { UDItype x0 = (UDItype) 0x3535353535353535ULL; __gnu_saturate1usq (&x0); w ((unsigned long long) x0); }
  { UDItype x0 = (UDItype) 0x8181818181818181ULL; __gnu_saturate1usq (&x0); w ((unsigned long long) x0); }
  { UDItype x0 = (UDItype) 0x0101010101017f01ULL; __gnu_saturate1usq (&x0); w ((unsigned long long) x0); }
  { DItype x0 = (DItype) 0x3535353535353535ULL; DItype x1 = (DItype) 0x2121212121212121ULL; __gnu_saturate2da (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { DItype x0 = (DItype) 0x8181818181818181ULL; DItype x1 = (DItype) 0x0303030303030303ULL; __gnu_saturate2da (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { DItype x0 = (DItype) 0x0101010101017f01ULL; DItype x1 = (DItype) 0xc1c1c1c1c1c1c1c1ULL; __gnu_saturate2da (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { DItype x0 = (DItype) 0x3535353535353535ULL; DItype x1 = (DItype) 0x2121212121212121ULL; __gnu_saturate2dq (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { DItype x0 = (DItype) 0x8181818181818181ULL; DItype x1 = (DItype) 0x0303030303030303ULL; __gnu_saturate2dq (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { DItype x0 = (DItype) 0x0101010101017f01ULL; DItype x1 = (DItype) 0xc1c1c1c1c1c1c1c1ULL; __gnu_saturate2dq (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { UDItype x0 = (UDItype) 0x3535353535353535ULL; UDItype x1 = (UDItype) 0x2121212121212121ULL; __gnu_saturate2uda (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { UDItype x0 = (UDItype) 0x8181818181818181ULL; UDItype x1 = (UDItype) 0x0303030303030303ULL; __gnu_saturate2uda (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { UDItype x0 = (UDItype) 0x0101010101017f01ULL; UDItype x1 = (UDItype) 0xc1c1c1c1c1c1c1c1ULL; __gnu_saturate2uda (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { UDItype x0 = (UDItype) 0x3535353535353535ULL; UDItype x1 = (UDItype) 0x2121212121212121ULL; __gnu_saturate2udq (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { UDItype x0 = (UDItype) 0x8181818181818181ULL; UDItype x1 = (UDItype) 0x0303030303030303ULL; __gnu_saturate2udq (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { UDItype x0 = (UDItype) 0x0101010101017f01ULL; UDItype x1 = (UDItype) 0xc1c1c1c1c1c1c1c1ULL; __gnu_saturate2udq (&x0, &x1); w ((unsigned long long) x0); w ((unsigned long long) x1); }
  { w (fxbDA (__gnu_ssaddda3 (fxmDA (0x3535353535353535ULL), fxmDA (0x2121212121212121ULL)))); }
  { w (fxbDA (__gnu_ssaddda3 (fxmDA (0x8181818181818181ULL), fxmDA (0x0303030303030303ULL)))); }
  { w (fxbDA (__gnu_ssaddda3 (fxmDA (0x0101010101017f01ULL), fxmDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDQ (__gnu_ssadddq3 (fxmDQ (0x3535353535353535ULL), fxmDQ (0x2121212121212121ULL)))); }
  { w (fxbDQ (__gnu_ssadddq3 (fxmDQ (0x8181818181818181ULL), fxmDQ (0x0303030303030303ULL)))); }
  { w (fxbDQ (__gnu_ssadddq3 (fxmDQ (0x0101010101017f01ULL), fxmDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHA (__gnu_ssaddha3 (fxmHA (0x3535353535353535ULL), fxmHA (0x2121212121212121ULL)))); }
  { w (fxbHA (__gnu_ssaddha3 (fxmHA (0x8181818181818181ULL), fxmHA (0x0303030303030303ULL)))); }
  { w (fxbHA (__gnu_ssaddha3 (fxmHA (0x0101010101017f01ULL), fxmHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHQ (__gnu_ssaddhq3 (fxmHQ (0x3535353535353535ULL), fxmHQ (0x2121212121212121ULL)))); }
  { w (fxbHQ (__gnu_ssaddhq3 (fxmHQ (0x8181818181818181ULL), fxmHQ (0x0303030303030303ULL)))); }
  { w (fxbHQ (__gnu_ssaddhq3 (fxmHQ (0x0101010101017f01ULL), fxmHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbQQ (__gnu_ssaddqq3 (fxmQQ (0x3535353535353535ULL), fxmQQ (0x2121212121212121ULL)))); }
  { w (fxbQQ (__gnu_ssaddqq3 (fxmQQ (0x8181818181818181ULL), fxmQQ (0x0303030303030303ULL)))); }
  { w (fxbQQ (__gnu_ssaddqq3 (fxmQQ (0x0101010101017f01ULL), fxmQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSA (__gnu_ssaddsa3 (fxmSA (0x3535353535353535ULL), fxmSA (0x2121212121212121ULL)))); }
  { w (fxbSA (__gnu_ssaddsa3 (fxmSA (0x8181818181818181ULL), fxmSA (0x0303030303030303ULL)))); }
  { w (fxbSA (__gnu_ssaddsa3 (fxmSA (0x0101010101017f01ULL), fxmSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSQ (__gnu_ssaddsq3 (fxmSQ (0x3535353535353535ULL), fxmSQ (0x2121212121212121ULL)))); }
  { w (fxbSQ (__gnu_ssaddsq3 (fxmSQ (0x8181818181818181ULL), fxmSQ (0x0303030303030303ULL)))); }
  { w (fxbSQ (__gnu_ssaddsq3 (fxmSQ (0x0101010101017f01ULL), fxmSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDA (__gnu_ssashlda3 (fxmDA (0x3535353535353535ULL), 1))); }
  { w (fxbDA (__gnu_ssashlda3 (fxmDA (0x8181818181818181ULL), 2))); }
  { w (fxbDA (__gnu_ssashlda3 (fxmDA (0x0101010101017f01ULL), 3))); }
  { w (fxbDQ (__gnu_ssashldq3 (fxmDQ (0x3535353535353535ULL), 1))); }
  { w (fxbDQ (__gnu_ssashldq3 (fxmDQ (0x8181818181818181ULL), 2))); }
  { w (fxbDQ (__gnu_ssashldq3 (fxmDQ (0x0101010101017f01ULL), 3))); }
}
static void fxt47 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbHA (__gnu_ssashlha3 (fxmHA (0x3535353535353535ULL), 1))); }
  { w (fxbHA (__gnu_ssashlha3 (fxmHA (0x8181818181818181ULL), 2))); }
  { w (fxbHA (__gnu_ssashlha3 (fxmHA (0x0101010101017f01ULL), 3))); }
  { w (fxbHQ (__gnu_ssashlhq3 (fxmHQ (0x3535353535353535ULL), 1))); }
  { w (fxbHQ (__gnu_ssashlhq3 (fxmHQ (0x8181818181818181ULL), 2))); }
  { w (fxbHQ (__gnu_ssashlhq3 (fxmHQ (0x0101010101017f01ULL), 3))); }
  { w (fxbQQ (__gnu_ssashlqq3 (fxmQQ (0x3535353535353535ULL), 1))); }
  { w (fxbQQ (__gnu_ssashlqq3 (fxmQQ (0x8181818181818181ULL), 2))); }
  { w (fxbQQ (__gnu_ssashlqq3 (fxmQQ (0x0101010101017f01ULL), 3))); }
  { w (fxbSA (__gnu_ssashlsa3 (fxmSA (0x3535353535353535ULL), 1))); }
  { w (fxbSA (__gnu_ssashlsa3 (fxmSA (0x8181818181818181ULL), 2))); }
  { w (fxbSA (__gnu_ssashlsa3 (fxmSA (0x0101010101017f01ULL), 3))); }
  { w (fxbSQ (__gnu_ssashlsq3 (fxmSQ (0x3535353535353535ULL), 1))); }
  { w (fxbSQ (__gnu_ssashlsq3 (fxmSQ (0x8181818181818181ULL), 2))); }
  { w (fxbSQ (__gnu_ssashlsq3 (fxmSQ (0x0101010101017f01ULL), 3))); }
  { w (fxbDA (__gnu_ssdivda3 (fxmDA (0x3535353535353535ULL), fxmDA (0x2121212121212121ULL)))); }
  { w (fxbDA (__gnu_ssdivda3 (fxmDA (0x8181818181818181ULL), fxmDA (0x0303030303030303ULL)))); }
  { w (fxbDA (__gnu_ssdivda3 (fxmDA (0x0101010101017f01ULL), fxmDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDQ (__gnu_ssdivdq3 (fxmDQ (0x3535353535353535ULL), fxmDQ (0x2121212121212121ULL)))); }
  { w (fxbDQ (__gnu_ssdivdq3 (fxmDQ (0x8181818181818181ULL), fxmDQ (0x0303030303030303ULL)))); }
  { w (fxbDQ (__gnu_ssdivdq3 (fxmDQ (0x0101010101017f01ULL), fxmDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHA (__gnu_ssdivha3 (fxmHA (0x3535353535353535ULL), fxmHA (0x2121212121212121ULL)))); }
  { w (fxbHA (__gnu_ssdivha3 (fxmHA (0x8181818181818181ULL), fxmHA (0x0303030303030303ULL)))); }
  { w (fxbHA (__gnu_ssdivha3 (fxmHA (0x0101010101017f01ULL), fxmHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHQ (__gnu_ssdivhq3 (fxmHQ (0x3535353535353535ULL), fxmHQ (0x2121212121212121ULL)))); }
  { w (fxbHQ (__gnu_ssdivhq3 (fxmHQ (0x8181818181818181ULL), fxmHQ (0x0303030303030303ULL)))); }
  { w (fxbHQ (__gnu_ssdivhq3 (fxmHQ (0x0101010101017f01ULL), fxmHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbQQ (__gnu_ssdivqq3 (fxmQQ (0x3535353535353535ULL), fxmQQ (0x2121212121212121ULL)))); }
  { w (fxbQQ (__gnu_ssdivqq3 (fxmQQ (0x8181818181818181ULL), fxmQQ (0x0303030303030303ULL)))); }
  { w (fxbQQ (__gnu_ssdivqq3 (fxmQQ (0x0101010101017f01ULL), fxmQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSA (__gnu_ssdivsa3 (fxmSA (0x3535353535353535ULL), fxmSA (0x2121212121212121ULL)))); }
  { w (fxbSA (__gnu_ssdivsa3 (fxmSA (0x8181818181818181ULL), fxmSA (0x0303030303030303ULL)))); }
  { w (fxbSA (__gnu_ssdivsa3 (fxmSA (0x0101010101017f01ULL), fxmSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSQ (__gnu_ssdivsq3 (fxmSQ (0x3535353535353535ULL), fxmSQ (0x2121212121212121ULL)))); }
  { w (fxbSQ (__gnu_ssdivsq3 (fxmSQ (0x8181818181818181ULL), fxmSQ (0x0303030303030303ULL)))); }
  { w (fxbSQ (__gnu_ssdivsq3 (fxmSQ (0x0101010101017f01ULL), fxmSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDA (__gnu_ssmulda3 (fxmDA (0x3535353535353535ULL), fxmDA (0x2121212121212121ULL)))); }
  { w (fxbDA (__gnu_ssmulda3 (fxmDA (0x8181818181818181ULL), fxmDA (0x0303030303030303ULL)))); }
  { w (fxbDA (__gnu_ssmulda3 (fxmDA (0x0101010101017f01ULL), fxmDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDQ (__gnu_ssmuldq3 (fxmDQ (0x3535353535353535ULL), fxmDQ (0x2121212121212121ULL)))); }
  { w (fxbDQ (__gnu_ssmuldq3 (fxmDQ (0x8181818181818181ULL), fxmDQ (0x0303030303030303ULL)))); }
  { w (fxbDQ (__gnu_ssmuldq3 (fxmDQ (0x0101010101017f01ULL), fxmDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHA (__gnu_ssmulha3 (fxmHA (0x3535353535353535ULL), fxmHA (0x2121212121212121ULL)))); }
  { w (fxbHA (__gnu_ssmulha3 (fxmHA (0x8181818181818181ULL), fxmHA (0x0303030303030303ULL)))); }
  { w (fxbHA (__gnu_ssmulha3 (fxmHA (0x0101010101017f01ULL), fxmHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHQ (__gnu_ssmulhq3 (fxmHQ (0x3535353535353535ULL), fxmHQ (0x2121212121212121ULL)))); }
  { w (fxbHQ (__gnu_ssmulhq3 (fxmHQ (0x8181818181818181ULL), fxmHQ (0x0303030303030303ULL)))); }
  { w (fxbHQ (__gnu_ssmulhq3 (fxmHQ (0x0101010101017f01ULL), fxmHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbQQ (__gnu_ssmulqq3 (fxmQQ (0x3535353535353535ULL), fxmQQ (0x2121212121212121ULL)))); }
  { w (fxbQQ (__gnu_ssmulqq3 (fxmQQ (0x8181818181818181ULL), fxmQQ (0x0303030303030303ULL)))); }
  { w (fxbQQ (__gnu_ssmulqq3 (fxmQQ (0x0101010101017f01ULL), fxmQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSA (__gnu_ssmulsa3 (fxmSA (0x3535353535353535ULL), fxmSA (0x2121212121212121ULL)))); }
  { w (fxbSA (__gnu_ssmulsa3 (fxmSA (0x8181818181818181ULL), fxmSA (0x0303030303030303ULL)))); }
  { w (fxbSA (__gnu_ssmulsa3 (fxmSA (0x0101010101017f01ULL), fxmSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSQ (__gnu_ssmulsq3 (fxmSQ (0x3535353535353535ULL), fxmSQ (0x2121212121212121ULL)))); }
  { w (fxbSQ (__gnu_ssmulsq3 (fxmSQ (0x8181818181818181ULL), fxmSQ (0x0303030303030303ULL)))); }
  { w (fxbSQ (__gnu_ssmulsq3 (fxmSQ (0x0101010101017f01ULL), fxmSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDA (__gnu_ssnegda2 (fxmDA (0x3535353535353535ULL)))); }
  { w (fxbDA (__gnu_ssnegda2 (fxmDA (0x8181818181818181ULL)))); }
  { w (fxbDA (__gnu_ssnegda2 (fxmDA (0x0101010101017f01ULL)))); }
}
static void fxt48 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbDQ (__gnu_ssnegdq2 (fxmDQ (0x3535353535353535ULL)))); }
  { w (fxbDQ (__gnu_ssnegdq2 (fxmDQ (0x8181818181818181ULL)))); }
  { w (fxbDQ (__gnu_ssnegdq2 (fxmDQ (0x0101010101017f01ULL)))); }
  { w (fxbHA (__gnu_ssnegha2 (fxmHA (0x3535353535353535ULL)))); }
  { w (fxbHA (__gnu_ssnegha2 (fxmHA (0x8181818181818181ULL)))); }
  { w (fxbHA (__gnu_ssnegha2 (fxmHA (0x0101010101017f01ULL)))); }
  { w (fxbHQ (__gnu_ssneghq2 (fxmHQ (0x3535353535353535ULL)))); }
  { w (fxbHQ (__gnu_ssneghq2 (fxmHQ (0x8181818181818181ULL)))); }
  { w (fxbHQ (__gnu_ssneghq2 (fxmHQ (0x0101010101017f01ULL)))); }
  { w (fxbQQ (__gnu_ssnegqq2 (fxmQQ (0x3535353535353535ULL)))); }
  { w (fxbQQ (__gnu_ssnegqq2 (fxmQQ (0x8181818181818181ULL)))); }
  { w (fxbQQ (__gnu_ssnegqq2 (fxmQQ (0x0101010101017f01ULL)))); }
  { w (fxbSA (__gnu_ssnegsa2 (fxmSA (0x3535353535353535ULL)))); }
  { w (fxbSA (__gnu_ssnegsa2 (fxmSA (0x8181818181818181ULL)))); }
  { w (fxbSA (__gnu_ssnegsa2 (fxmSA (0x0101010101017f01ULL)))); }
  { w (fxbSQ (__gnu_ssnegsq2 (fxmSQ (0x3535353535353535ULL)))); }
  { w (fxbSQ (__gnu_ssnegsq2 (fxmSQ (0x8181818181818181ULL)))); }
  { w (fxbSQ (__gnu_ssnegsq2 (fxmSQ (0x0101010101017f01ULL)))); }
  { w (fxbDA (__gnu_sssubda3 (fxmDA (0x3535353535353535ULL), fxmDA (0x2121212121212121ULL)))); }
  { w (fxbDA (__gnu_sssubda3 (fxmDA (0x8181818181818181ULL), fxmDA (0x0303030303030303ULL)))); }
  { w (fxbDA (__gnu_sssubda3 (fxmDA (0x0101010101017f01ULL), fxmDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDQ (__gnu_sssubdq3 (fxmDQ (0x3535353535353535ULL), fxmDQ (0x2121212121212121ULL)))); }
  { w (fxbDQ (__gnu_sssubdq3 (fxmDQ (0x8181818181818181ULL), fxmDQ (0x0303030303030303ULL)))); }
  { w (fxbDQ (__gnu_sssubdq3 (fxmDQ (0x0101010101017f01ULL), fxmDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHA (__gnu_sssubha3 (fxmHA (0x3535353535353535ULL), fxmHA (0x2121212121212121ULL)))); }
  { w (fxbHA (__gnu_sssubha3 (fxmHA (0x8181818181818181ULL), fxmHA (0x0303030303030303ULL)))); }
  { w (fxbHA (__gnu_sssubha3 (fxmHA (0x0101010101017f01ULL), fxmHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHQ (__gnu_sssubhq3 (fxmHQ (0x3535353535353535ULL), fxmHQ (0x2121212121212121ULL)))); }
  { w (fxbHQ (__gnu_sssubhq3 (fxmHQ (0x8181818181818181ULL), fxmHQ (0x0303030303030303ULL)))); }
  { w (fxbHQ (__gnu_sssubhq3 (fxmHQ (0x0101010101017f01ULL), fxmHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbQQ (__gnu_sssubqq3 (fxmQQ (0x3535353535353535ULL), fxmQQ (0x2121212121212121ULL)))); }
  { w (fxbQQ (__gnu_sssubqq3 (fxmQQ (0x8181818181818181ULL), fxmQQ (0x0303030303030303ULL)))); }
  { w (fxbQQ (__gnu_sssubqq3 (fxmQQ (0x0101010101017f01ULL), fxmQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSA (__gnu_sssubsa3 (fxmSA (0x3535353535353535ULL), fxmSA (0x2121212121212121ULL)))); }
  { w (fxbSA (__gnu_sssubsa3 (fxmSA (0x8181818181818181ULL), fxmSA (0x0303030303030303ULL)))); }
  { w (fxbSA (__gnu_sssubsa3 (fxmSA (0x0101010101017f01ULL), fxmSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSQ (__gnu_sssubsq3 (fxmSQ (0x3535353535353535ULL), fxmSQ (0x2121212121212121ULL)))); }
  { w (fxbSQ (__gnu_sssubsq3 (fxmSQ (0x8181818181818181ULL), fxmSQ (0x0303030303030303ULL)))); }
  { w (fxbSQ (__gnu_sssubsq3 (fxmSQ (0x0101010101017f01ULL), fxmSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDA (__gnu_subda3 (fxmDA (0x3535353535353535ULL), fxmDA (0x2121212121212121ULL)))); }
  { w (fxbDA (__gnu_subda3 (fxmDA (0x8181818181818181ULL), fxmDA (0x0303030303030303ULL)))); }
  { w (fxbDA (__gnu_subda3 (fxmDA (0x0101010101017f01ULL), fxmDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbDQ (__gnu_subdq3 (fxmDQ (0x3535353535353535ULL), fxmDQ (0x2121212121212121ULL)))); }
  { w (fxbDQ (__gnu_subdq3 (fxmDQ (0x8181818181818181ULL), fxmDQ (0x0303030303030303ULL)))); }
  { w (fxbDQ (__gnu_subdq3 (fxmDQ (0x0101010101017f01ULL), fxmDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHA (__gnu_subha3 (fxmHA (0x3535353535353535ULL), fxmHA (0x2121212121212121ULL)))); }
  { w (fxbHA (__gnu_subha3 (fxmHA (0x8181818181818181ULL), fxmHA (0x0303030303030303ULL)))); }
  { w (fxbHA (__gnu_subha3 (fxmHA (0x0101010101017f01ULL), fxmHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbHQ (__gnu_subhq3 (fxmHQ (0x3535353535353535ULL), fxmHQ (0x2121212121212121ULL)))); }
  { w (fxbHQ (__gnu_subhq3 (fxmHQ (0x8181818181818181ULL), fxmHQ (0x0303030303030303ULL)))); }
  { w (fxbHQ (__gnu_subhq3 (fxmHQ (0x0101010101017f01ULL), fxmHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbQQ (__gnu_subqq3 (fxmQQ (0x3535353535353535ULL), fxmQQ (0x2121212121212121ULL)))); }
  { w (fxbQQ (__gnu_subqq3 (fxmQQ (0x8181818181818181ULL), fxmQQ (0x0303030303030303ULL)))); }
  { w (fxbQQ (__gnu_subqq3 (fxmQQ (0x0101010101017f01ULL), fxmQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSA (__gnu_subsa3 (fxmSA (0x3535353535353535ULL), fxmSA (0x2121212121212121ULL)))); }
  { w (fxbSA (__gnu_subsa3 (fxmSA (0x8181818181818181ULL), fxmSA (0x0303030303030303ULL)))); }
  { w (fxbSA (__gnu_subsa3 (fxmSA (0x0101010101017f01ULL), fxmSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbSQ (__gnu_subsq3 (fxmSQ (0x3535353535353535ULL), fxmSQ (0x2121212121212121ULL)))); }
  { w (fxbSQ (__gnu_subsq3 (fxmSQ (0x8181818181818181ULL), fxmSQ (0x0303030303030303ULL)))); }
  { w (fxbSQ (__gnu_subsq3 (fxmSQ (0x0101010101017f01ULL), fxmSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
}
static void fxt49 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUDA (__gnu_subuda3 (fxmUDA (0x3535353535353535ULL), fxmUDA (0x2121212121212121ULL)))); }
  { w (fxbUDA (__gnu_subuda3 (fxmUDA (0x8181818181818181ULL), fxmUDA (0x0303030303030303ULL)))); }
  { w (fxbUDA (__gnu_subuda3 (fxmUDA (0x0101010101017f01ULL), fxmUDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDQ (__gnu_subudq3 (fxmUDQ (0x3535353535353535ULL), fxmUDQ (0x2121212121212121ULL)))); }
  { w (fxbUDQ (__gnu_subudq3 (fxmUDQ (0x8181818181818181ULL), fxmUDQ (0x0303030303030303ULL)))); }
  { w (fxbUDQ (__gnu_subudq3 (fxmUDQ (0x0101010101017f01ULL), fxmUDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHA (__gnu_subuha3 (fxmUHA (0x3535353535353535ULL), fxmUHA (0x2121212121212121ULL)))); }
  { w (fxbUHA (__gnu_subuha3 (fxmUHA (0x8181818181818181ULL), fxmUHA (0x0303030303030303ULL)))); }
  { w (fxbUHA (__gnu_subuha3 (fxmUHA (0x0101010101017f01ULL), fxmUHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHQ (__gnu_subuhq3 (fxmUHQ (0x3535353535353535ULL), fxmUHQ (0x2121212121212121ULL)))); }
  { w (fxbUHQ (__gnu_subuhq3 (fxmUHQ (0x8181818181818181ULL), fxmUHQ (0x0303030303030303ULL)))); }
  { w (fxbUHQ (__gnu_subuhq3 (fxmUHQ (0x0101010101017f01ULL), fxmUHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUQQ (__gnu_subuqq3 (fxmUQQ (0x3535353535353535ULL), fxmUQQ (0x2121212121212121ULL)))); }
  { w (fxbUQQ (__gnu_subuqq3 (fxmUQQ (0x8181818181818181ULL), fxmUQQ (0x0303030303030303ULL)))); }
  { w (fxbUQQ (__gnu_subuqq3 (fxmUQQ (0x0101010101017f01ULL), fxmUQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSA (__gnu_subusa3 (fxmUSA (0x3535353535353535ULL), fxmUSA (0x2121212121212121ULL)))); }
  { w (fxbUSA (__gnu_subusa3 (fxmUSA (0x8181818181818181ULL), fxmUSA (0x0303030303030303ULL)))); }
  { w (fxbUSA (__gnu_subusa3 (fxmUSA (0x0101010101017f01ULL), fxmUSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSQ (__gnu_subusq3 (fxmUSQ (0x3535353535353535ULL), fxmUSQ (0x2121212121212121ULL)))); }
  { w (fxbUSQ (__gnu_subusq3 (fxmUSQ (0x8181818181818181ULL), fxmUSQ (0x0303030303030303ULL)))); }
  { w (fxbUSQ (__gnu_subusq3 (fxmUSQ (0x0101010101017f01ULL), fxmUSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDA (__gnu_udivuda3 (fxmUDA (0x3535353535353535ULL), fxmUDA (0x2121212121212121ULL)))); }
  { w (fxbUDA (__gnu_udivuda3 (fxmUDA (0x8181818181818181ULL), fxmUDA (0x0303030303030303ULL)))); }
  { w (fxbUDA (__gnu_udivuda3 (fxmUDA (0x0101010101017f01ULL), fxmUDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDQ (__gnu_udivudq3 (fxmUDQ (0x3535353535353535ULL), fxmUDQ (0x2121212121212121ULL)))); }
  { w (fxbUDQ (__gnu_udivudq3 (fxmUDQ (0x8181818181818181ULL), fxmUDQ (0x0303030303030303ULL)))); }
  { w (fxbUDQ (__gnu_udivudq3 (fxmUDQ (0x0101010101017f01ULL), fxmUDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHA (__gnu_udivuha3 (fxmUHA (0x3535353535353535ULL), fxmUHA (0x2121212121212121ULL)))); }
  { w (fxbUHA (__gnu_udivuha3 (fxmUHA (0x8181818181818181ULL), fxmUHA (0x0303030303030303ULL)))); }
  { w (fxbUHA (__gnu_udivuha3 (fxmUHA (0x0101010101017f01ULL), fxmUHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHQ (__gnu_udivuhq3 (fxmUHQ (0x3535353535353535ULL), fxmUHQ (0x2121212121212121ULL)))); }
  { w (fxbUHQ (__gnu_udivuhq3 (fxmUHQ (0x8181818181818181ULL), fxmUHQ (0x0303030303030303ULL)))); }
  { w (fxbUHQ (__gnu_udivuhq3 (fxmUHQ (0x0101010101017f01ULL), fxmUHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUQQ (__gnu_udivuqq3 (fxmUQQ (0x3535353535353535ULL), fxmUQQ (0x2121212121212121ULL)))); }
  { w (fxbUQQ (__gnu_udivuqq3 (fxmUQQ (0x8181818181818181ULL), fxmUQQ (0x0303030303030303ULL)))); }
  { w (fxbUQQ (__gnu_udivuqq3 (fxmUQQ (0x0101010101017f01ULL), fxmUQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSA (__gnu_udivusa3 (fxmUSA (0x3535353535353535ULL), fxmUSA (0x2121212121212121ULL)))); }
  { w (fxbUSA (__gnu_udivusa3 (fxmUSA (0x8181818181818181ULL), fxmUSA (0x0303030303030303ULL)))); }
  { w (fxbUSA (__gnu_udivusa3 (fxmUSA (0x0101010101017f01ULL), fxmUSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSQ (__gnu_udivusq3 (fxmUSQ (0x3535353535353535ULL), fxmUSQ (0x2121212121212121ULL)))); }
  { w (fxbUSQ (__gnu_udivusq3 (fxmUSQ (0x8181818181818181ULL), fxmUSQ (0x0303030303030303ULL)))); }
  { w (fxbUSQ (__gnu_udivusq3 (fxmUSQ (0x0101010101017f01ULL), fxmUSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDA (__gnu_usadduda3 (fxmUDA (0x3535353535353535ULL), fxmUDA (0x2121212121212121ULL)))); }
  { w (fxbUDA (__gnu_usadduda3 (fxmUDA (0x8181818181818181ULL), fxmUDA (0x0303030303030303ULL)))); }
  { w (fxbUDA (__gnu_usadduda3 (fxmUDA (0x0101010101017f01ULL), fxmUDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDQ (__gnu_usaddudq3 (fxmUDQ (0x3535353535353535ULL), fxmUDQ (0x2121212121212121ULL)))); }
  { w (fxbUDQ (__gnu_usaddudq3 (fxmUDQ (0x8181818181818181ULL), fxmUDQ (0x0303030303030303ULL)))); }
  { w (fxbUDQ (__gnu_usaddudq3 (fxmUDQ (0x0101010101017f01ULL), fxmUDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHA (__gnu_usadduha3 (fxmUHA (0x3535353535353535ULL), fxmUHA (0x2121212121212121ULL)))); }
  { w (fxbUHA (__gnu_usadduha3 (fxmUHA (0x8181818181818181ULL), fxmUHA (0x0303030303030303ULL)))); }
  { w (fxbUHA (__gnu_usadduha3 (fxmUHA (0x0101010101017f01ULL), fxmUHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHQ (__gnu_usadduhq3 (fxmUHQ (0x3535353535353535ULL), fxmUHQ (0x2121212121212121ULL)))); }
  { w (fxbUHQ (__gnu_usadduhq3 (fxmUHQ (0x8181818181818181ULL), fxmUHQ (0x0303030303030303ULL)))); }
  { w (fxbUHQ (__gnu_usadduhq3 (fxmUHQ (0x0101010101017f01ULL), fxmUHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUQQ (__gnu_usadduqq3 (fxmUQQ (0x3535353535353535ULL), fxmUQQ (0x2121212121212121ULL)))); }
  { w (fxbUQQ (__gnu_usadduqq3 (fxmUQQ (0x8181818181818181ULL), fxmUQQ (0x0303030303030303ULL)))); }
  { w (fxbUQQ (__gnu_usadduqq3 (fxmUQQ (0x0101010101017f01ULL), fxmUQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSA (__gnu_usaddusa3 (fxmUSA (0x3535353535353535ULL), fxmUSA (0x2121212121212121ULL)))); }
  { w (fxbUSA (__gnu_usaddusa3 (fxmUSA (0x8181818181818181ULL), fxmUSA (0x0303030303030303ULL)))); }
  { w (fxbUSA (__gnu_usaddusa3 (fxmUSA (0x0101010101017f01ULL), fxmUSA (0xc1c1c1c1c1c1c1c1ULL)))); }
}
static void fxt50 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUSQ (__gnu_usaddusq3 (fxmUSQ (0x3535353535353535ULL), fxmUSQ (0x2121212121212121ULL)))); }
  { w (fxbUSQ (__gnu_usaddusq3 (fxmUSQ (0x8181818181818181ULL), fxmUSQ (0x0303030303030303ULL)))); }
  { w (fxbUSQ (__gnu_usaddusq3 (fxmUSQ (0x0101010101017f01ULL), fxmUSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDA (__gnu_usashluda3 (fxmUDA (0x3535353535353535ULL), 1))); }
  { w (fxbUDA (__gnu_usashluda3 (fxmUDA (0x8181818181818181ULL), 2))); }
  { w (fxbUDA (__gnu_usashluda3 (fxmUDA (0x0101010101017f01ULL), 3))); }
  { w (fxbUDQ (__gnu_usashludq3 (fxmUDQ (0x3535353535353535ULL), 1))); }
  { w (fxbUDQ (__gnu_usashludq3 (fxmUDQ (0x8181818181818181ULL), 2))); }
  { w (fxbUDQ (__gnu_usashludq3 (fxmUDQ (0x0101010101017f01ULL), 3))); }
  { w (fxbUHA (__gnu_usashluha3 (fxmUHA (0x3535353535353535ULL), 1))); }
  { w (fxbUHA (__gnu_usashluha3 (fxmUHA (0x8181818181818181ULL), 2))); }
  { w (fxbUHA (__gnu_usashluha3 (fxmUHA (0x0101010101017f01ULL), 3))); }
  { w (fxbUHQ (__gnu_usashluhq3 (fxmUHQ (0x3535353535353535ULL), 1))); }
  { w (fxbUHQ (__gnu_usashluhq3 (fxmUHQ (0x8181818181818181ULL), 2))); }
  { w (fxbUHQ (__gnu_usashluhq3 (fxmUHQ (0x0101010101017f01ULL), 3))); }
  { w (fxbUQQ (__gnu_usashluqq3 (fxmUQQ (0x3535353535353535ULL), 1))); }
  { w (fxbUQQ (__gnu_usashluqq3 (fxmUQQ (0x8181818181818181ULL), 2))); }
  { w (fxbUQQ (__gnu_usashluqq3 (fxmUQQ (0x0101010101017f01ULL), 3))); }
  { w (fxbUSA (__gnu_usashlusa3 (fxmUSA (0x3535353535353535ULL), 1))); }
  { w (fxbUSA (__gnu_usashlusa3 (fxmUSA (0x8181818181818181ULL), 2))); }
  { w (fxbUSA (__gnu_usashlusa3 (fxmUSA (0x0101010101017f01ULL), 3))); }
  { w (fxbUSQ (__gnu_usashlusq3 (fxmUSQ (0x3535353535353535ULL), 1))); }
  { w (fxbUSQ (__gnu_usashlusq3 (fxmUSQ (0x8181818181818181ULL), 2))); }
  { w (fxbUSQ (__gnu_usashlusq3 (fxmUSQ (0x0101010101017f01ULL), 3))); }
  { w (fxbUDA (__gnu_usdivuda3 (fxmUDA (0x3535353535353535ULL), fxmUDA (0x2121212121212121ULL)))); }
  { w (fxbUDA (__gnu_usdivuda3 (fxmUDA (0x8181818181818181ULL), fxmUDA (0x0303030303030303ULL)))); }
  { w (fxbUDA (__gnu_usdivuda3 (fxmUDA (0x0101010101017f01ULL), fxmUDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDQ (__gnu_usdivudq3 (fxmUDQ (0x3535353535353535ULL), fxmUDQ (0x2121212121212121ULL)))); }
  { w (fxbUDQ (__gnu_usdivudq3 (fxmUDQ (0x8181818181818181ULL), fxmUDQ (0x0303030303030303ULL)))); }
  { w (fxbUDQ (__gnu_usdivudq3 (fxmUDQ (0x0101010101017f01ULL), fxmUDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHA (__gnu_usdivuha3 (fxmUHA (0x3535353535353535ULL), fxmUHA (0x2121212121212121ULL)))); }
  { w (fxbUHA (__gnu_usdivuha3 (fxmUHA (0x8181818181818181ULL), fxmUHA (0x0303030303030303ULL)))); }
  { w (fxbUHA (__gnu_usdivuha3 (fxmUHA (0x0101010101017f01ULL), fxmUHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHQ (__gnu_usdivuhq3 (fxmUHQ (0x3535353535353535ULL), fxmUHQ (0x2121212121212121ULL)))); }
  { w (fxbUHQ (__gnu_usdivuhq3 (fxmUHQ (0x8181818181818181ULL), fxmUHQ (0x0303030303030303ULL)))); }
  { w (fxbUHQ (__gnu_usdivuhq3 (fxmUHQ (0x0101010101017f01ULL), fxmUHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUQQ (__gnu_usdivuqq3 (fxmUQQ (0x3535353535353535ULL), fxmUQQ (0x2121212121212121ULL)))); }
  { w (fxbUQQ (__gnu_usdivuqq3 (fxmUQQ (0x8181818181818181ULL), fxmUQQ (0x0303030303030303ULL)))); }
  { w (fxbUQQ (__gnu_usdivuqq3 (fxmUQQ (0x0101010101017f01ULL), fxmUQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSA (__gnu_usdivusa3 (fxmUSA (0x3535353535353535ULL), fxmUSA (0x2121212121212121ULL)))); }
  { w (fxbUSA (__gnu_usdivusa3 (fxmUSA (0x8181818181818181ULL), fxmUSA (0x0303030303030303ULL)))); }
  { w (fxbUSA (__gnu_usdivusa3 (fxmUSA (0x0101010101017f01ULL), fxmUSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSQ (__gnu_usdivusq3 (fxmUSQ (0x3535353535353535ULL), fxmUSQ (0x2121212121212121ULL)))); }
  { w (fxbUSQ (__gnu_usdivusq3 (fxmUSQ (0x8181818181818181ULL), fxmUSQ (0x0303030303030303ULL)))); }
  { w (fxbUSQ (__gnu_usdivusq3 (fxmUSQ (0x0101010101017f01ULL), fxmUSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDA (__gnu_usmuluda3 (fxmUDA (0x3535353535353535ULL), fxmUDA (0x2121212121212121ULL)))); }
  { w (fxbUDA (__gnu_usmuluda3 (fxmUDA (0x8181818181818181ULL), fxmUDA (0x0303030303030303ULL)))); }
  { w (fxbUDA (__gnu_usmuluda3 (fxmUDA (0x0101010101017f01ULL), fxmUDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDQ (__gnu_usmuludq3 (fxmUDQ (0x3535353535353535ULL), fxmUDQ (0x2121212121212121ULL)))); }
  { w (fxbUDQ (__gnu_usmuludq3 (fxmUDQ (0x8181818181818181ULL), fxmUDQ (0x0303030303030303ULL)))); }
  { w (fxbUDQ (__gnu_usmuludq3 (fxmUDQ (0x0101010101017f01ULL), fxmUDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHA (__gnu_usmuluha3 (fxmUHA (0x3535353535353535ULL), fxmUHA (0x2121212121212121ULL)))); }
  { w (fxbUHA (__gnu_usmuluha3 (fxmUHA (0x8181818181818181ULL), fxmUHA (0x0303030303030303ULL)))); }
  { w (fxbUHA (__gnu_usmuluha3 (fxmUHA (0x0101010101017f01ULL), fxmUHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHQ (__gnu_usmuluhq3 (fxmUHQ (0x3535353535353535ULL), fxmUHQ (0x2121212121212121ULL)))); }
  { w (fxbUHQ (__gnu_usmuluhq3 (fxmUHQ (0x8181818181818181ULL), fxmUHQ (0x0303030303030303ULL)))); }
  { w (fxbUHQ (__gnu_usmuluhq3 (fxmUHQ (0x0101010101017f01ULL), fxmUHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUQQ (__gnu_usmuluqq3 (fxmUQQ (0x3535353535353535ULL), fxmUQQ (0x2121212121212121ULL)))); }
  { w (fxbUQQ (__gnu_usmuluqq3 (fxmUQQ (0x8181818181818181ULL), fxmUQQ (0x0303030303030303ULL)))); }
  { w (fxbUQQ (__gnu_usmuluqq3 (fxmUQQ (0x0101010101017f01ULL), fxmUQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
}
static void fxt51 (void) {
  double wg = 0.0; (void) wg;
  { w (fxbUSA (__gnu_usmulusa3 (fxmUSA (0x3535353535353535ULL), fxmUSA (0x2121212121212121ULL)))); }
  { w (fxbUSA (__gnu_usmulusa3 (fxmUSA (0x8181818181818181ULL), fxmUSA (0x0303030303030303ULL)))); }
  { w (fxbUSA (__gnu_usmulusa3 (fxmUSA (0x0101010101017f01ULL), fxmUSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSQ (__gnu_usmulusq3 (fxmUSQ (0x3535353535353535ULL), fxmUSQ (0x2121212121212121ULL)))); }
  { w (fxbUSQ (__gnu_usmulusq3 (fxmUSQ (0x8181818181818181ULL), fxmUSQ (0x0303030303030303ULL)))); }
  { w (fxbUSQ (__gnu_usmulusq3 (fxmUSQ (0x0101010101017f01ULL), fxmUSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDA (__gnu_usneguda2 (fxmUDA (0x3535353535353535ULL)))); }
  { w (fxbUDA (__gnu_usneguda2 (fxmUDA (0x8181818181818181ULL)))); }
  { w (fxbUDA (__gnu_usneguda2 (fxmUDA (0x0101010101017f01ULL)))); }
  { w (fxbUDQ (__gnu_usnegudq2 (fxmUDQ (0x3535353535353535ULL)))); }
  { w (fxbUDQ (__gnu_usnegudq2 (fxmUDQ (0x8181818181818181ULL)))); }
  { w (fxbUDQ (__gnu_usnegudq2 (fxmUDQ (0x0101010101017f01ULL)))); }
  { w (fxbUHA (__gnu_usneguha2 (fxmUHA (0x3535353535353535ULL)))); }
  { w (fxbUHA (__gnu_usneguha2 (fxmUHA (0x8181818181818181ULL)))); }
  { w (fxbUHA (__gnu_usneguha2 (fxmUHA (0x0101010101017f01ULL)))); }
  { w (fxbUHQ (__gnu_usneguhq2 (fxmUHQ (0x3535353535353535ULL)))); }
  { w (fxbUHQ (__gnu_usneguhq2 (fxmUHQ (0x8181818181818181ULL)))); }
  { w (fxbUHQ (__gnu_usneguhq2 (fxmUHQ (0x0101010101017f01ULL)))); }
  { w (fxbUQQ (__gnu_usneguqq2 (fxmUQQ (0x3535353535353535ULL)))); }
  { w (fxbUQQ (__gnu_usneguqq2 (fxmUQQ (0x8181818181818181ULL)))); }
  { w (fxbUQQ (__gnu_usneguqq2 (fxmUQQ (0x0101010101017f01ULL)))); }
  { w (fxbUSA (__gnu_usnegusa2 (fxmUSA (0x3535353535353535ULL)))); }
  { w (fxbUSA (__gnu_usnegusa2 (fxmUSA (0x8181818181818181ULL)))); }
  { w (fxbUSA (__gnu_usnegusa2 (fxmUSA (0x0101010101017f01ULL)))); }
  { w (fxbUSQ (__gnu_usnegusq2 (fxmUSQ (0x3535353535353535ULL)))); }
  { w (fxbUSQ (__gnu_usnegusq2 (fxmUSQ (0x8181818181818181ULL)))); }
  { w (fxbUSQ (__gnu_usnegusq2 (fxmUSQ (0x0101010101017f01ULL)))); }
  { w (fxbUDA (__gnu_ussubuda3 (fxmUDA (0x3535353535353535ULL), fxmUDA (0x2121212121212121ULL)))); }
  { w (fxbUDA (__gnu_ussubuda3 (fxmUDA (0x8181818181818181ULL), fxmUDA (0x0303030303030303ULL)))); }
  { w (fxbUDA (__gnu_ussubuda3 (fxmUDA (0x0101010101017f01ULL), fxmUDA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUDQ (__gnu_ussubudq3 (fxmUDQ (0x3535353535353535ULL), fxmUDQ (0x2121212121212121ULL)))); }
  { w (fxbUDQ (__gnu_ussubudq3 (fxmUDQ (0x8181818181818181ULL), fxmUDQ (0x0303030303030303ULL)))); }
  { w (fxbUDQ (__gnu_ussubudq3 (fxmUDQ (0x0101010101017f01ULL), fxmUDQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHA (__gnu_ussubuha3 (fxmUHA (0x3535353535353535ULL), fxmUHA (0x2121212121212121ULL)))); }
  { w (fxbUHA (__gnu_ussubuha3 (fxmUHA (0x8181818181818181ULL), fxmUHA (0x0303030303030303ULL)))); }
  { w (fxbUHA (__gnu_ussubuha3 (fxmUHA (0x0101010101017f01ULL), fxmUHA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUHQ (__gnu_ussubuhq3 (fxmUHQ (0x3535353535353535ULL), fxmUHQ (0x2121212121212121ULL)))); }
  { w (fxbUHQ (__gnu_ussubuhq3 (fxmUHQ (0x8181818181818181ULL), fxmUHQ (0x0303030303030303ULL)))); }
  { w (fxbUHQ (__gnu_ussubuhq3 (fxmUHQ (0x0101010101017f01ULL), fxmUHQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUQQ (__gnu_ussubuqq3 (fxmUQQ (0x3535353535353535ULL), fxmUQQ (0x2121212121212121ULL)))); }
  { w (fxbUQQ (__gnu_ussubuqq3 (fxmUQQ (0x8181818181818181ULL), fxmUQQ (0x0303030303030303ULL)))); }
  { w (fxbUQQ (__gnu_ussubuqq3 (fxmUQQ (0x0101010101017f01ULL), fxmUQQ (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSA (__gnu_ussubusa3 (fxmUSA (0x3535353535353535ULL), fxmUSA (0x2121212121212121ULL)))); }
  { w (fxbUSA (__gnu_ussubusa3 (fxmUSA (0x8181818181818181ULL), fxmUSA (0x0303030303030303ULL)))); }
  { w (fxbUSA (__gnu_ussubusa3 (fxmUSA (0x0101010101017f01ULL), fxmUSA (0xc1c1c1c1c1c1c1c1ULL)))); }
  { w (fxbUSQ (__gnu_ussubusq3 (fxmUSQ (0x3535353535353535ULL), fxmUSQ (0x2121212121212121ULL)))); }
  { w (fxbUSQ (__gnu_ussubusq3 (fxmUSQ (0x8181818181818181ULL), fxmUSQ (0x0303030303030303ULL)))); }
  { w (fxbUSQ (__gnu_ussubusq3 (fxmUSQ (0x0101010101017f01ULL), fxmUSQ (0xc1c1c1c1c1c1c1c1ULL)))); }
}
static void fxall (void) { fxt0 (); fxt1 (); fxt2 (); fxt3 (); fxt4 (); fxt5 (); fxt6 (); fxt7 (); fxt8 (); fxt9 (); fxt10 (); fxt11 (); fxt12 (); fxt13 (); fxt14 (); fxt15 (); fxt16 (); fxt17 (); fxt18 (); fxt19 (); fxt20 (); fxt21 (); fxt22 (); fxt23 (); fxt24 (); fxt25 (); fxt26 (); fxt27 (); fxt28 (); fxt29 (); fxt30 (); fxt31 (); fxt32 (); fxt33 (); fxt34 (); fxt35 (); fxt36 (); fxt37 (); fxt38 (); fxt39 (); fxt40 (); fxt41 (); fxt42 (); fxt43 (); fxt44 (); fxt45 (); fxt46 (); fxt47 (); fxt48 (); fxt49 (); fxt50 (); fxt51 (); }
