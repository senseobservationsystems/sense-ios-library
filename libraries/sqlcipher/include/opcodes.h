/* Automatically generated.  Do not edit */
/* See the mkopcodeh.awk script for details */
#define OP_Function        1 /* synopsis: r[P3]=func(r[P2@P5])             */
#define OP_Savepoint       2
#define OP_AutoCommit      3
#define OP_Transaction     4
#define OP_SorterNext      5
#define OP_PrevIfOpen      6
#define OP_NextIfOpen      7
#define OP_Prev            8
#define OP_Next            9
#define OP_AggStep        10 /* synopsis: accum=r[P3] step(r[P2@P5])       */
#define OP_Checkpoint     11
#define OP_JournalMode    12
#define OP_Vacuum         13
#define OP_VFilter        14 /* synopsis: iplan=r[P3] zplan='P4'           */
#define OP_VUpdate        15 /* synopsis: data=r[P3@P2]                    */
#define OP_Goto           16
#define OP_Gosub          17
#define OP_Return         18
#define OP_Not            19 /* same as TK_NOT, synopsis: r[P2]= !r[P1]    */
#define OP_InitCoroutine  20
#define OP_EndCoroutine   21
#define OP_Yield          22
#define OP_HaltIfNull     23 /* synopsis: if r[P3]=null halt               */
#define OP_Halt           24
#define OP_Integer        25 /* synopsis: r[P2]=P1                         */
#define OP_Int64          26 /* synopsis: r[P2]=P4                         */
#define OP_String         27 /* synopsis: r[P2]='P4' (len=P1)              */
#define OP_Null           28 /* synopsis: r[P2..P3]=NULL                   */
#define OP_SoftNull       29 /* synopsis: r[P1]=NULL                       */
#define OP_Blob           30 /* synopsis: r[P2]=P4 (len=P1)                */
#define OP_Variable       31 /* synopsis: r[P2]=parameter(P1,P4)           */
#define OP_Move           32 /* synopsis: r[P2@P3]=r[P1@P3]                */
#define OP_Copy           33 /* synopsis: r[P2@P3+1]=r[P1@P3+1]            */
#define OP_SCopy          34 /* synopsis: r[P2]=r[P1]                      */
#define OP_ResultRow      35 /* synopsis: output=r[P1@P2]                  */
#define OP_CollSeq        36
#define OP_AddImm         37 /* synopsis: r[P1]=r[P1]+P2                   */
#define OP_MustBeInt      38
#define OP_RealAffinity   39
#define OP_Permutation    40
#define OP_Compare        41 /* synopsis: r[P1@P3] <-> r[P2@P3]            */
#define OP_Jump           42
#define OP_Once           43
#define OP_If             44
#define OP_IfNot          45
#define OP_Column         46 /* synopsis: r[P3]=PX                         */
#define OP_Affinity       47 /* synopsis: affinity(r[P1@P2])               */
#define OP_MakeRecord     48 /* synopsis: r[P3]=mkrec(r[P1@P2])            */
#define OP_Count          49 /* synopsis: r[P2]=count()                    */
#define OP_ReadCookie     50
#define OP_SetCookie      51
#define OP_ReopenIdx      52 /* synopsis: root=P2 iDb=P3                   */
#define OP_OpenRead       53 /* synopsis: root=P2 iDb=P3                   */
#define OP_OpenWrite      54 /* synopsis: root=P2 iDb=P3                   */
#define OP_OpenAutoindex  55 /* synopsis: nColumn=P2                       */
#define OP_OpenEphemeral  56 /* synopsis: nColumn=P2                       */
#define OP_SorterOpen     57
#define OP_OpenPseudo     58 /* synopsis: P3 columns in r[P2]              */
#define OP_Close          59
#define OP_SeekLT         60 /* synopsis: key=r[P3@P4]                     */
#define OP_SeekLE         61 /* synopsis: key=r[P3@P4]                     */
#define OP_SeekGE         62 /* synopsis: key=r[P3@P4]                     */
#define OP_SeekGT         63 /* synopsis: key=r[P3@P4]                     */
#define OP_Seek           64 /* synopsis: intkey=r[P2]                     */
#define OP_NoConflict     65 /* synopsis: key=r[P3@P4]                     */
#define OP_NotFound       66 /* synopsis: key=r[P3@P4]                     */
#define OP_Found          67 /* synopsis: key=r[P3@P4]                     */
#define OP_NotExists      68 /* synopsis: intkey=r[P3]                     */
#define OP_Sequence       69 /* synopsis: r[P2]=cursor[P1].ctr++           */
#define OP_NewRowid       70 /* synopsis: r[P2]=rowid                      */
#define OP_Or             71 /* same as TK_OR, synopsis: r[P3]=(r[P1] || r[P2]) */
#define OP_And            72 /* same as TK_AND, synopsis: r[P3]=(r[P1] && r[P2]) */
#define OP_Insert         73 /* synopsis: intkey=r[P3] data=r[P2]          */
#define OP_InsertInt      74 /* synopsis: intkey=P3 data=r[P2]             */
#define OP_Delete         75
#define OP_IsNull         76 /* same as TK_ISNULL, synopsis: if r[P1]==NULL goto P2 */
#define OP_NotNull        77 /* same as TK_NOTNULL, synopsis: if r[P1]!=NULL goto P2 */
#define OP_Ne             78 /* same as TK_NE, synopsis: if r[P1]!=r[P3] goto P2 */
#define OP_Eq             79 /* same as TK_EQ, synopsis: if r[P1]==r[P3] goto P2 */
#define OP_Gt             80 /* same as TK_GT, synopsis: if r[P1]>r[P3] goto P2 */
#define OP_Le             81 /* same as TK_LE, synopsis: if r[P1]<=r[P3] goto P2 */
#define OP_Lt             82 /* same as TK_LT, synopsis: if r[P1]<r[P3] goto P2 */
#define OP_Ge             83 /* same as TK_GE, synopsis: if r[P1]>=r[P3] goto P2 */
#define OP_ResetCount     84
#define OP_BitAnd         85 /* same as TK_BITAND, synopsis: r[P3]=r[P1]&r[P2] */
#define OP_BitOr          86 /* same as TK_BITOR, synopsis: r[P3]=r[P1]|r[P2] */
#define OP_ShiftLeft      87 /* same as TK_LSHIFT, synopsis: r[P3]=r[P2]<<r[P1] */
#define OP_ShiftRight     88 /* same as TK_RSHIFT, synopsis: r[P3]=r[P2]>>r[P1] */
#define OP_Add            89 /* same as TK_PLUS, synopsis: r[P3]=r[P1]+r[P2] */
#define OP_Subtract       90 /* same as TK_MINUS, synopsis: r[P3]=r[P2]-r[P1] */
#define OP_Multiply       91 /* same as TK_STAR, synopsis: r[P3]=r[P1]*r[P2] */
#define OP_Divide         92 /* same as TK_SLASH, synopsis: r[P3]=r[P2]/r[P1] */
#define OP_Remainder      93 /* same as TK_REM, synopsis: r[P3]=r[P2]%r[P1] */
#define OP_Concat         94 /* same as TK_CONCAT, synopsis: r[P3]=r[P2]+r[P1] */
#define OP_SorterCompare  95 /* synopsis: if key(P1)!=trim(r[P3],P4) goto P2 */
#define OP_BitNot         96 /* same as TK_BITNOT, synopsis: r[P1]= ~r[P1] */
#define OP_String8        97 /* same as TK_STRING, synopsis: r[P2]='P4'    */
#define OP_SorterData     98 /* synopsis: r[P2]=data                       */
#define OP_RowKey         99 /* synopsis: r[P2]=key                        */
#define OP_RowData       100 /* synopsis: r[P2]=data                       */
#define OP_Rowid         101 /* synopsis: r[P2]=rowid                      */
#define OP_NullRow       102
#define OP_Last          103
#define OP_SorterSort    104
#define OP_Sort          105
#define OP_Rewind        106
#define OP_SorterInsert  107
#define OP_IdxInsert     108 /* synopsis: key=r[P2]                        */
#define OP_IdxDelete     109 /* synopsis: key=r[P2@P3]                     */
#define OP_IdxRowid      110 /* synopsis: r[P2]=rowid                      */
#define OP_IdxLE         111 /* synopsis: key=r[P3@P4]                     */
#define OP_IdxGT         112 /* synopsis: key=r[P3@P4]                     */
#define OP_IdxLT         113 /* synopsis: key=r[P3@P4]                     */
#define OP_IdxGE         114 /* synopsis: key=r[P3@P4]                     */
#define OP_Destroy       115
#define OP_Clear         116
#define OP_ResetSorter   117
#define OP_CreateIndex   118 /* synopsis: r[P2]=root iDb=P1                */
#define OP_CreateTable   119 /* synopsis: r[P2]=root iDb=P1                */
#define OP_ParseSchema   120
#define OP_LoadAnalysis  121
#define OP_DropTable     122
#define OP_DropIndex     123
#define OP_DropTrigger   124
#define OP_IntegrityCk   125
#define OP_RowSetAdd     126 /* synopsis: rowset(P1)=r[P2]                 */
#define OP_RowSetRead    127 /* synopsis: r[P3]=rowset(P1)                 */
#define OP_RowSetTest    128 /* synopsis: if r[P3] in rowset(P1) goto P2   */
#define OP_Program       129
#define OP_Param         130
#define OP_FkCounter     131 /* synopsis: fkctr[P1]+=P2                    */
#define OP_FkIfZero      132 /* synopsis: if fkctr[P1]==0 goto P2          */
#define OP_Real          133 /* same as TK_FLOAT, synopsis: r[P2]=P4       */
#define OP_MemMax        134 /* synopsis: r[P1]=max(r[P1],r[P2])           */
#define OP_IfPos         135 /* synopsis: if r[P1]>0 goto P2               */
#define OP_IfNeg         136 /* synopsis: r[P1]+=P3, if r[P1]<0 goto P2    */
#define OP_IfZero        137 /* synopsis: r[P1]+=P3, if r[P1]==0 goto P2   */
#define OP_AggFinal      138 /* synopsis: accum=r[P1] N=P2                 */
#define OP_IncrVacuum    139
#define OP_Expire        140
#define OP_TableLock     141 /* synopsis: iDb=P1 root=P2 write=P3          */
#define OP_VBegin        142
#define OP_ToText        143 /* same as TK_TO_TEXT                         */
#define OP_ToBlob        144 /* same as TK_TO_BLOB                         */
#define OP_ToNumeric     145 /* same as TK_TO_NUMERIC                      */
#define OP_ToInt         146 /* same as TK_TO_INT                          */
#define OP_ToReal        147 /* same as TK_TO_REAL                         */
#define OP_VCreate       148
#define OP_VDestroy      149
#define OP_VOpen         150
#define OP_VColumn       151 /* synopsis: r[P3]=vcolumn(P2)                */
#define OP_VNext         152
#define OP_VRename       153
#define OP_Pagecount     154
#define OP_MaxPgcnt      155
#define OP_Init          156 /* synopsis: Start at P2                      */
#define OP_Noop          157
#define OP_Explain       158


/* Properties such as "out2" or "jump" that are specified in
** comments following the "case" for each opcode in the vdbe.c
** are encoded into bitvectors as follows:
*/
#define OPFLG_JUMP            0x0001  /* jump:  P2 holds jmp target */
#define OPFLG_OUT2_PRERELEASE 0x0002  /* out2-prerelease: */
#define OPFLG_IN1             0x0004  /* in1:   P1 is an input */
#define OPFLG_IN2             0x0008  /* in2:   P2 is an input */
#define OPFLG_IN3             0x0010  /* in3:   P3 is an input */
#define OPFLG_OUT2            0x0020  /* out2:  P2 is an output */
#define OPFLG_OUT3            0x0040  /* out3:  P3 is an output */
#define OPFLG_INITIALIZER {\
/*   0 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01,\
/*   8 */ 0x01, 0x01, 0x00, 0x00, 0x02, 0x00, 0x01, 0x00,\
/*  16 */ 0x01, 0x01, 0x04, 0x24, 0x01, 0x04, 0x05, 0x10,\
/*  24 */ 0x00, 0x02, 0x02, 0x02, 0x02, 0x00, 0x02, 0x02,\
/*  32 */ 0x00, 0x00, 0x20, 0x00, 0x00, 0x04, 0x05, 0x04,\
/*  40 */ 0x00, 0x00, 0x01, 0x01, 0x05, 0x05, 0x00, 0x00,\
/*  48 */ 0x00, 0x02, 0x02, 0x10, 0x00, 0x00, 0x00, 0x00,\
/*  56 */ 0x00, 0x00, 0x00, 0x00, 0x11, 0x11, 0x11, 0x11,\
/*  64 */ 0x08, 0x11, 0x11, 0x11, 0x11, 0x02, 0x02, 0x4c,\
/*  72 */ 0x4c, 0x00, 0x00, 0x00, 0x05, 0x05, 0x15, 0x15,\
/*  80 */ 0x15, 0x15, 0x15, 0x15, 0x00, 0x4c, 0x4c, 0x4c,\
/*  88 */ 0x4c, 0x4c, 0x4c, 0x4c, 0x4c, 0x4c, 0x4c, 0x00,\
/*  96 */ 0x24, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01,\
/* 104 */ 0x01, 0x01, 0x01, 0x08, 0x08, 0x00, 0x02, 0x01,\
/* 112 */ 0x01, 0x01, 0x01, 0x02, 0x00, 0x00, 0x02, 0x02,\
/* 120 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x45,\
/* 128 */ 0x15, 0x01, 0x02, 0x00, 0x01, 0x02, 0x08, 0x05,\
/* 136 */ 0x05, 0x05, 0x00, 0x01, 0x00, 0x00, 0x00, 0x04,\
/* 144 */ 0x04, 0x04, 0x04, 0x04, 0x00, 0x00, 0x00, 0x00,\
/* 152 */ 0x01, 0x00, 0x02, 0x02, 0x01, 0x00, 0x00,}
