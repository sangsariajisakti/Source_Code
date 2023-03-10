//+--------------------------------------------------------------------------------+
//|                                MT4 JSON Plugin                                 |
//|                                  FXA, 2023                                     |
//+--------------------------------------------------------------------------------+
//------------------------------------------------------------------
#property copyright   "FXA, 2023 "
#property description "Capture order related events and send them to backend API"
#property version     "1.016"
#property strict


extern string  settings = "";//  API Parameters
input string host = "http://13.232.38.91/mt4/orders";//Set ports and host for Plugin
input int strat = 145656; //Unique Strategy ID - user should be able to change this

// Global variables \\
int deInitReason = -1;
int Timer=250;// TIme in Milliseconds for Timer Function.
// Variables for handling price data stream

enum enJAType
  {
   jtUNDEF, jtNULL, jtBOOL, jtINT, jtDBL, jtSTR, jtARRAY, jtOBJ
  };

//------------------------------------------------------------------ class CJAVal
class CJAVal
  {
public:
   virtual void      Clear(enJAType jt = jtUNDEF, bool savekey = false)
     {
      m_parent = NULL;

      if(!savekey)
         groupName = "";

      m_type = jt;
      m_bv   = false;
      m_iv   = 0;
      m_dv   = 0;
      m_prec = 5;
      m_sv   = "";
      ArrayResize(group, 0, 100);
     }
   virtual bool      Copy(const CJAVal &a)
     {
      groupName = a.groupName;
      CopyData(a);
      return true;
     }
   virtual void      CopyData(const CJAVal &a)
     {
      m_type = a.m_type;
      m_bv   = a.m_bv;
      m_iv   = a.m_iv;
      m_dv   = a.m_dv;
      m_prec = a.m_prec;
      m_sv   = a.m_sv;
      CopyArr(a);
     }
   virtual void      CopyArr(const CJAVal &a)
     {
      int n = ArrayResize(group, ArraySize(a.group));

      for(int i = 0; i < n; i++)
        {
         group [i] = a.group [i];
         group [i].m_parent = GetPointer(this);
        }
     }

public:
   CJAVal            group [];   // group
   string            groupName;  // group name
   string            m_lkey;
   CJAVal            *m_parent;
   enJAType          m_type;
   bool              m_bv;
   long              m_iv;
   double            m_dv;
   int               m_prec;
   string            m_sv;
   static int        code_page;

public:
                     CJAVal()
     {
      Clear();
     }
                     CJAVal(CJAVal *aparent, enJAType atype)
     {
      Clear();
      m_type = atype;
      m_parent = aparent;
     }
                     CJAVal(enJAType t, string a)
     {
      Clear();
      FromStr(t, a);
     }
                     CJAVal(const int a)
     {
      Clear();
      m_type = jtINT;
      m_iv   = a;
      m_dv   = (double)m_iv;
      m_sv   = IntegerToString(m_iv);
      m_bv   = m_iv != 0;
     }
                     CJAVal(const long a)
     {
      Clear();
      m_type = jtINT;
      m_iv   = a;
      m_dv   = (double)m_iv;
      m_sv   = IntegerToString(m_iv);
      m_bv   = m_iv != 0;
     }
                     CJAVal(const double a, int aprec = -100)
     {
      Clear();
      m_type = jtDBL;
      m_dv = a;

      if(aprec > -100)
         m_prec = aprec;

      m_iv = (long)m_dv;
      m_sv = DoubleToString(m_dv, m_prec);
      m_bv = m_iv != 0;
     }
                     CJAVal(const bool a)
     {
      Clear();
      m_type = jtBOOL;
      m_bv   = a;
      m_iv   = m_bv;
      m_dv   = m_bv;
      m_sv   = IntegerToString(m_iv);
     }
                     CJAVal(const CJAVal &a)
     {
      Clear();
      Copy(a);
     }
                    ~CJAVal()
     {
      Clear();
     }

public:
   int               Size()
     {
      return ArraySize(group);
     }
   virtual bool      IsNumeric()
     {
      return m_type == jtDBL || m_type == jtINT;
     }
   virtual CJAVal    *FindKey(string akey)
     {
      for(int i = Size() - 1; i >= 0; --i)
         if(group [i].groupName == akey)
            return GetPointer(group [i]);
      return NULL;
     }
   virtual CJAVal    *HasKey(string akey, enJAType atype = jtUNDEF)
     {
      CJAVal *e = FindKey(akey);
      if(CheckPointer(e) != POINTER_INVALID)
        {
         if(atype == jtUNDEF || atype == e.m_type)
            return GetPointer(e);
        }
      return NULL;
     }
   virtual CJAVal *  operator [](string akey);
   virtual CJAVal *  operator [](int i);
   void              operator= (const CJAVal &a)
     {
      Copy(a);
     }
   void              operator= (const int a)
     {
      m_type = jtINT;
      m_iv   = a;
      m_dv   = (double)m_iv;
      m_bv   = m_iv != 0;
     }
   void              operator= (const long a)
     {
      m_type = jtINT;
      m_iv   = a;
      m_dv   = (double)m_iv;
      m_bv   = m_iv != 0;
     }
   void              operator= (const double a)
     {
      m_type = jtDBL;
      m_dv   = a;
      m_iv   = (long)m_dv;
      m_bv   = m_iv != 0;
     }
   void              operator= (const bool a)
     {
      m_type = jtBOOL;
      m_bv   = a;
      m_iv   = (long)m_bv;
      m_dv   = (double)m_bv;
     }
   void              operator= (string a)
     {
      m_type = (a != NULL) ? jtSTR : jtNULL;
      m_sv   = a;
      m_iv   = StringToInteger(m_sv);
      m_dv   = StringToDouble(m_sv);
      m_bv   = a != NULL;
     }

   bool              operator== (const int a)
     {
      return m_iv == a;
     }
   bool              operator== (const long a)
     {
      return m_iv == a;
     }
   bool              operator== (const double a)
     {
      return m_dv == a;
     }
   bool              operator== (const bool a)
     {
      return m_bv == a;
     }
   bool              operator== (string a)
     {
      return m_sv == a;
     }

   bool              operator!= (const int a)
     {
      return m_iv != a;
     }
   bool              operator!= (const long a)
     {
      return m_iv != a;
     }
   bool              operator!= (const double a)
     {
      return m_dv != a;
     }
   bool              operator!= (const bool a)
     {
      return m_bv != a;
     }
   bool              operator!= (string a)
     {
      return m_sv != a;
     }

   long              ToInt() const
     {
      return m_iv;
     }
   double            ToDbl() const
     {
      return m_dv;
     }
   bool              ToBool() const
     {
      return m_bv;
     }
   string            ToStr()
     {
      return m_sv;
     }

   virtual void      FromStr(enJAType t, string a)
     {
      m_type = t;
      switch(m_type)
        {
         case jtBOOL:
            m_bv = (StringToInteger(a) != 0);
            m_iv = (long)m_bv;
            m_dv = (double)m_bv;
            m_sv = a;
            break;
         case jtINT:
            m_iv = StringToInteger(a);
            m_dv = (double)m_iv;
            m_sv = a;
            m_bv = m_iv != 0;
            break;
         case jtDBL:
            m_dv = StringToDouble(a);
            m_iv = (long)m_dv;
            m_sv = a;
            m_bv = m_iv != 0;
            break;
         case jtSTR:
            m_sv   = Unescape(a);
            m_type = (m_sv != NULL) ? jtSTR : jtNULL;
            m_iv   = StringToInteger(m_sv);
            m_dv   = StringToDouble(m_sv);
            m_bv   = m_sv != NULL;
            break;
        }
     }
   virtual string    GetStr(char &js [], int i, int slen)
     {
      if(slen == 0)
         return "";
      char cc [];
      ArrayCopy(cc, js, 0, i, slen);
      return CharArrayToString(cc, 0, WHOLE_ARRAY, CJAVal::code_page);
     }

   virtual void      Set(const CJAVal &a)
     {
      if(m_type == jtUNDEF)
         m_type = jtOBJ;
      CopyData(a);
     }
   virtual void      Set(const CJAVal &list []);
   virtual CJAVal    *Add(const CJAVal &item)
     {
      if(m_type == jtUNDEF)
         m_type = jtARRAY;
      /*ASSERT(m_type==jtOBJ || m_type==jtARRAY);*/ return AddBase(item);
     } // ??????????
   virtual CJAVal    *Add(const int a)
     {
      CJAVal item(a);
      return Add(item);
     }
   virtual CJAVal    *Add(const long a)
     {
      CJAVal item(a);
      return Add(item);
     }
   virtual CJAVal    *Add(const double a, int aprec = -2)
     {
      CJAVal item(a, aprec);
      return Add(item);
     }
   virtual CJAVal    *Add(const bool a)
     {
      CJAVal item(a);
      return Add(item);
     }
   virtual CJAVal    *Add(string a)
     {
      CJAVal item(jtSTR, a);
      return Add(item);
     }
   virtual CJAVal    *AddBase(const CJAVal &item)  // ??????????
     {
      int c = Size();
      ArrayResize(group, c + 1, 100);
      group [c] = item;
      group [c].m_parent = GetPointer(this);
      return GetPointer(group [c]);
     }
   virtual CJAVal    *New()
     {
      if(m_type == jtUNDEF)
         m_type = jtARRAY;
      /*ASSERT(m_type==jtOBJ || m_type==jtARRAY);*/ return NewBase();
     } // ??????????
   virtual CJAVal    *NewBase()  // ??????????
     {
      int c = Size();
      ArrayResize(group, c + 1, 100);
      return GetPointer(group [c]);
     }

   virtual string    Escape(string a);
   virtual string    Unescape(string a);
public:
   virtual void      Serialize(string &js, bool bf = false, bool bcoma = false);
   virtual string    Serialize()
     {
      string js;
      Serialize(js);
      return js;
     }
   virtual bool      Deserialize(char &js [], int slen, int &i);
   virtual bool      ExtrStr(char &js [], int slen, int &i);
   virtual bool      Deserialize(string js, int acp = CP_ACP)
     {
      int i = 0;
      Clear();
      CJAVal::code_page = acp;
      char arr [];
      int slen = StringToCharArray(js, arr, 0, WHOLE_ARRAY, CJAVal::code_page);
      return Deserialize(arr, slen, i);
     }
   virtual bool      Deserialize(char &js [], int acp = CP_ACP)
     {
      int i = 0;
      Clear();
      CJAVal::code_page = acp;
      return Deserialize(js, ArraySize(js), i);
     }
  };

int CJAVal::code_page = CP_ACP;

//------------------------------------------------------------------ operator[]
CJAVal *CJAVal::operator[](string akey)
  {
   if(m_type == jtUNDEF)
      m_type = jtOBJ;
   CJAVal *v = FindKey(akey);
   if(v)
      return v;
   CJAVal b(GetPointer(this), jtUNDEF);
   b.groupName = akey;
   v = Add(b);
   return v;
  }
//------------------------------------------------------------------ operator[]
CJAVal *CJAVal::operator[](int i)
  {
   if(m_type == jtUNDEF)
      m_type = jtARRAY;
   while(i >= Size())
     {
      CJAVal b(GetPointer(this), jtUNDEF);
      if(CheckPointer(Add(b)) == POINTER_INVALID)
         return NULL;
     }
   return GetPointer(group [i]);
  }
//------------------------------------------------------------------ Set
void CJAVal::Set(const CJAVal &list [])
  {
   if(m_type == jtUNDEF)
      m_type = jtARRAY;
   int n = ArrayResize(group, ArraySize(list), 100);
   for(int i = 0; i < n; ++i)
     {
      group [i] = list [i];
      group [i].m_parent = GetPointer(this);
     }
  }
//------------------------------------------------------------------ Serialize
void CJAVal::Serialize(string &js, bool bkey/*=false*/, bool coma/*=false*/)
  {
   if(m_type == jtUNDEF)
      return;
   if(coma)
      js += ",";
   if(bkey)
      js += StringFormat("\"%s\":", groupName);
   int _n = Size();
   switch(m_type)
     {
      case jtNULL:
         js += "null";
         break;
      case jtBOOL:
         js += (m_bv ? "true" : "false");
         break;
      case jtINT:
         js += IntegerToString(m_iv);
         break;
      case jtDBL:
         js += DoubleToString(m_dv, 5);
         break;
      case jtSTR:
        {
         string ss = Escape(m_sv);
         if(StringLen(ss) > 0)
            js += StringFormat("\"%s\"", ss);
         else
            js += "null";
        }
      break;
      case jtARRAY:
         js += "[";
         for(int i = 0; i < _n; i++)
            group [i].Serialize(js, false, i > 0);
         js += "]";
         break;
      case jtOBJ:
         js += "{";
         for(int i = 0; i < _n; i++)
            group [i].Serialize(js, true, i > 0);
         js += "}";
         break;
     }
  }

//------------------------------------------------------------------ Deserialize
bool CJAVal::Deserialize(char &js [], int slen, int &i)
  {
   string num = "0123456789+-.eE";
   int i0 = i;
   for(; i < slen; i++)
     {
      char c = js [i];
      if(c == 0)
         break;
      switch(c)
        {
         case '\t':
         case '\r':
         case '\n':
         case ' ': // ?????????? ?? ????? ???????
            i0 = i + 1;
            break;

         case '[': // ?????? ???????. ??????? ??????? ? ???????? ?? js
           {
            i0 = i + 1;
            if(m_type != jtUNDEF)  // ???? ???????? ??? ????? ???, ?? ??? ??????
              {
               Print(groupName + " " + string(__LINE__));
               return false;
              }
            m_type = jtARRAY; // ?????? ??? ????????
            i++;
            CJAVal val(GetPointer(this), jtUNDEF);
            while(val.Deserialize(js, slen, i))
              {
               if(val.m_type != jtUNDEF)
                  Add(val);
               if(val.m_type == jtINT || val.m_type == jtDBL || val.m_type == jtARRAY)
                  i++;
               val.Clear();
               val.m_parent = GetPointer(this);
               if(js [i] == ']')
                  break;
               i++;
               if(i >= slen)
                 {
                  Print(groupName + " " + string(__LINE__));
                  return false;
                 }
              }
            if(i >= slen)
               return false;
            return js [i] == ']' || js [i] == 0;
           }
         break;
         case ']':
            if(!m_parent)
               return false;
            return m_parent.m_type == jtARRAY; // ????? ???????, ??????? ???????? ?????? ???? ????????

         case ':':
           {
            if(m_lkey == "")
              {
               Print(groupName + " " + string(__LINE__));
               return false;
              }
            CJAVal val(GetPointer(this), jtUNDEF);
            CJAVal *oc = Add(val);  // ??? ??????? ???? ?? ?????????
            oc.groupName = m_lkey;
            m_lkey = ""; // ?????? ??? ?????
            i++;
            if(!oc.Deserialize(js, slen, i))
              {
               Print(groupName + " " + string(__LINE__));
               return false;
              }
            break;
           }
         case ',': // ??????????? ???????? // ??? ???????? ??? ?????? ???? ?????????
            i0 = i + 1;
            if(!m_parent && m_type != jtOBJ)
              {
               Print(groupName + " " + string(__LINE__));
               return false;
              }
            else
               if(m_parent)
                 {
                  if(m_parent.m_type != jtARRAY && m_parent.m_type != jtOBJ)
                    {
                     Print(groupName + " " + string(__LINE__));
                     return false;
                    }
                  if(m_parent.m_type == jtARRAY && m_type == jtUNDEF)
                     return true;
                 }
            break;

         // ????????? ????? ???? ?????? ? ??????? / ???? ??????????????
         case '{': // ?????? ???????. ??????? ?????? ? ???????? ??? ?? js
            i0 = i + 1;
            if(m_type != jtUNDEF)  // ?????? ????
              {
               Print(groupName + " " + string(__LINE__));
               return false;
              }
            m_type = jtOBJ; // ?????? ??? ????????
            i++;
            if(!Deserialize(js, slen, i))   // ?????????? ???
              {
               Print(groupName + " " + string(__LINE__));
               return false;
              }
            if(i >= slen)
               return false;
            return js [i] == '}' || js [i] == 0;
            break;
         case '}':
            return m_type == jtOBJ; // ????? ???????, ??????? ???????? ?????? ???? ????????

         case 't':
         case 'T': // ?????? true
         case 'f':
         case 'F': // ?????? false
            if(m_type != jtUNDEF)  // ?????? ????
              {
               Print(groupName + " " + string(__LINE__));
               return false;
              }
            m_type = jtBOOL; // ?????? ??? ????????
            if(i + 3 < slen)
              {
               if(StringCompare(GetStr(js, i, 4), "true", false) == 0)
                 {
                  m_bv = true;
                  i += 3;
                  return true;
                 }
              }
            if(i + 4 < slen)
              {
               if(StringCompare(GetStr(js, i, 5), "false", false) == 0)
                 {
                  m_bv = false;
                  i += 4;
                  return true;
                 }
              }
            Print(groupName + " " + string(__LINE__));
            return false; // ?? ??? ??? ??? ????? ??????
            break;
         case 'n':
         case 'N': // ?????? null
            if(m_type != jtUNDEF)  // ?????? ????
              {
               Print(groupName + " " + string(__LINE__));
               return false;
              }
            m_type = jtNULL; // ?????? ??? ????????
            if(i + 3 < slen)
               if(StringCompare(GetStr(js, i, 4), "null", false) == 0)
                 {
                  i += 3;
                  return true;
                 }
            Print(groupName + " " + string(__LINE__));
            return false; // ?? NULL ??? ????? ??????
            break;

         case '0':
         case '1':
         case '2':
         case '3':
         case '4':
         case '5':
         case '6':
         case '7':
         case '8':
         case '9':
         case '-':
         case '+':
         case '.': // ?????? ?????
           {
            if(m_type != jtUNDEF)  // ?????? ????
              {
               Print(groupName + " " + string(__LINE__));
               return false;
              }
            bool dbl = false; // ?????? ??? ????????
            int is = i;
            while(js [i] != 0 && i < slen)
              {
               i++;
               if(StringFind(num, GetStr(js, i, 1)) < 0)
                  break;
               if(!dbl)
                  dbl = (js [i] == '.' || js [i] == 'e' || js [i] == 'E');
              }
            m_sv = GetStr(js, is, i - is);
            if(dbl)
              {
               m_type = jtDBL;
               m_dv = StringToDouble(m_sv);
               m_iv = (long)m_dv;
               m_bv = m_iv != 0;
              }
            else // ??????? ??? ????????
              {
               m_type = jtINT;
               m_iv = StringToInteger(m_sv);
               m_dv = (double)m_iv;
               m_bv = m_iv != 0;
              }
            i--;
            return true; // ???????????? ?? 1 ?????? ????? ? ?????
            break;
           }
         case '\"': // ?????? ??? ????? ??????
            if(m_type == jtOBJ)  // ???? ??? ??? ??????????? ? ???? ?? ?????
              {
               i++;
               int is = i;
               if(!ExtrStr(js, slen, i))   // ??? ????, ???? ?? ????? ??????
                 {
                  Print(groupName + " " + string(__LINE__));
                  return false;
                 }
               m_lkey = GetStr(js, is, i - is);
              }
            else
              {
               if(m_type != jtUNDEF)  // ?????? ????
                 {
                  Print(groupName + " " + string(__LINE__));
                  return false;
                 }
               m_type = jtSTR; // ?????? ??? ????????
               i++;
               int is = i;
               if(!ExtrStr(js, slen, i))
                 {
                  Print(groupName + " " + string(__LINE__));
                  return false;
                 }
               FromStr(jtSTR, GetStr(js, is, i - is));
               return true;
              }
            break;
        }
     }
   return true;
  }

//------------------------------------------------------------------ ExtrStr
bool CJAVal::ExtrStr(char &js [], int slen, int &i)
  {
   for(; js [i] != 0 && i < slen; i++)
     {
      char c = js [i];
      if(c == '\"')
         break; // ????? ??????
      if(c == '\\' && i + 1 < slen)
        {
         i++;
         c = js [i];
         switch(c)
           {
            case '/':
            case '\\':
            case '\"':
            case 'b':
            case 'f':
            case 'r':
            case 'n':
            case 't':
               break; // ??? ???????????
            case 'u': // \uXXXX
              {
               i++;
               for(int j = 0; j < 4 && i < slen && js [i] != 0; j++, i++)
                 {
                  if(!((js [i] >= '0' && js [i] <= '9') || (js [i] >= 'A' && js [i] <= 'F') || (js [i] >= 'a' && js [i] <= 'f')))  // ?? hex
                    {
                     Print(groupName + " " + CharToString(js [i]) + " " + string(__LINE__));
                     return false;
                    }
                 }
               i--;
               break;
              }
            default:
               break; /*{ return false; } // ????????????? ?????? ? ?????????????? */
           }
        }
     }
   return true;
  }
//------------------------------------------------------------------ Escape
string CJAVal::Escape(string a)
  {
   ushort as [], s [];
   int n = StringToShortArray(a, as);
   if(ArrayResize(s, 2 * n) != 2 * n)
      return NULL;
   int j = 0;
   for(int i = 0; i < n; i++)
     {
      switch(as [i])
        {
         case '\\':
            s [j] = '\\';
            j++;
            s [j] = '\\';
            j++;
            break;
         case '"':
            s [j] = '\\';
            j++;
            s [j] = '"';
            j++;
            break;
         case '/':
            s [j] = '\\';
            j++;
            s [j] = '/';
            j++;
            break;
         case 8:
            s [j] = '\\';
            j++;
            s [j] = 'b';
            j++;
            break;
         case 12:
            s [j] = '\\';
            j++;
            s [j] = 'f';
            j++;
            break;
         case '\n':
            s [j] = '\\';
            j++;
            s [j] = 'n';
            j++;
            break;
         case '\r':
            s [j] = '\\';
            j++;
            s [j] = 'r';
            j++;
            break;
         case '\t':
            s [j] = '\\';
            j++;
            s [j] = 't';
            j++;
            break;
         default:
            s [j] = as [i];
            j++;
            break;
        }
     }
   a = ShortArrayToString(s, 0, j);
   return a;
  }
//------------------------------------------------------------------ Unescape
string CJAVal::Unescape(string a)
  {
   ushort as [], s [];
   int n = StringToShortArray(a, as);
   if(ArrayResize(s, n) != n)
      return NULL;
   int j = 0, i = 0;
   while(i < n)
     {
      ushort c = as [i];
      if(c == '\\' && i < n - 1)
        {
         switch(as [i + 1])
           {
            case '\\':
               c = '\\';
               i++;
               break;
            case '"':
               c = '"';
               i++;
               break;
            case '/':
               c = '/';
               i++;
               break;
            case 'b':
               c = 8;
               /*08='\b'*/;
               i++;
               break;
            case 'f':
               c = 12;
               /*0c=\f*/ i++;
               break;
            case 'n':
               c = '\n';
               i++;
               break;
            case 'r':
               c = '\r';
               i++;
               break;
            case 't':
               c = '\t';
               i++;
               break;
            case 'u': // \uXXXX
              {
               i += 2;
               ushort k = 0;
               for(int jj = 0; jj < 4 && i < n; jj++, i++)
                 {
                  c = as [i];
                  ushort h = 0;
                  if(c >= '0' && c <= '9')
                     h = c - '0';
                  else
                     if(c >= 'A' && c <= 'F')
                        h = c - 'A' + 10;
                     else
                        if(c >= 'a' && c <= 'f')
                           h = c - 'a' + 10;
                        else
                           break; // ?? hex
                  k += h * (ushort)pow(16, (3 - jj));
                 }
               i--;
               c = k;
               break;
              }
           }
        }
      s [j] = c;
      j++;
      i++;
     }
   a = ShortArrayToString(s, 0, j);
   return a;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetMillisecondTimer(Timer);
   GUI();
// Skip reloading of the EA script when the reason to reload is a chart timeframe change
   if(deInitReason != REASON_CHARTCHANGE)
     {
      EventSetMillisecondTimer(1);
      //  return(INIT_FAILED);
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   deInitReason = reason;
   GlobalVariablesDeleteAll();
   EventKillTimer();
   ObjectsDeleteAll(0,-1,OBJ_LABEL);
  }
//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
  {
   int eventOrderSend = EOS(),eventOrderClose=EOC(),eventOrderCloseStop=ECT(),eventStopModify=ECM(),eventProfitModify=ECN();
   if(Event(eventOrderSend))
      MarketOrder(eventOrderSend);
   if(Event(eventOrderClose))
     {
      MarketClosure(eventOrderClose, 1);
      W = 0;
     }
   if(Event(eventOrderCloseStop))
      MarketClosure(eventOrderCloseStop,2);
   if(Event(eventStopModify))
      MarketStopsModify(eventStopModify);
   if(Event(eventProfitModify))
      MarketProfitModify(eventProfitModify);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CPTS(int tf)
  {
   string tfs;
   switch(tf)
     {
      case PERIOD_M1:
         tfs = "M1"  ;
         break;
      case PERIOD_M5:
         tfs = "M5"  ;
         break;
      case PERIOD_M15:
         tfs = "M15" ;
         break;
      case PERIOD_M30:
         tfs = "M30" ;
         break;
      case PERIOD_H1:
         tfs = "H1"  ;
         break;
      case PERIOD_H4:
         tfs = "H4"  ;
         break;
      case PERIOD_D1:
         tfs = "D1"  ;
         break;
      case PERIOD_W1:
         tfs = "W1"  ;
         break;
      case PERIOD_MN1:
         tfs = "MN";
     }
   return(tfs);
  }
//+------------------------------------------------------------------+
//| Error reporting                                                  |
//+------------------------------------------------------------------+
bool CheckError(string funcName)  {      return false;  }
bool show=true;
//+------------------------------------------------------------------+
//| Get error message by error id                                    |
//+------------------------------------------------------------------+
string GetErrorID(int error)
  {
   switch(error)
     {
      // Custom errors
      case 65537:
         return("ERR_DESERIALIZATION");
         break;
      case 65538:
         return("ERR_WRONG_ACTION");
         break;
      case 65539:
         return("ERR_WRONG_ACTION_TYPE");
         break;
      case 65540:
         return("ERR_CLEAR_SUBSCRIPTIONS_FAILED");
         break;
      case 65541:
         return("ERR_RETRIEVE_DATA_FAILED");
         break;
      case 65542:
         return("ERR_CVS_FILE_CREATION_FAILED");
         break;
      default:
         return("ERR_CODE_UNKNOWN="+IntegerToString(error));
         break;
     }
  }

//+------------------------------------------------------------------+
//| Return a textual description of the deinitialization reason code |
//+------------------------------------------------------------------+
string getUninitReasonText(int reasonCode)
  {
   string text="";
//---
   switch(reasonCode)
     {
      case REASON_ACCOUNT:
         text="Account was changed";
         break;
      case REASON_CHARTCHANGE:
         text="Symbol or timeframe was changed";
         break;
      case REASON_CHARTCLOSE:
         text="Chart was closed";
         break;
      case REASON_PARAMETERS:
         text="Input-parameter was changed";
         break;
      case REASON_RECOMPILE:
         text="Program "+__FILE__+" was recompiled";
         break;
      case REASON_REMOVE:
         text="Program "+__FILE__+" was removed from chart";
         break;
      case REASON_TEMPLATE:
         text="New template was applied to chart";
         break;
      default:
         text="Another reason";
     }
//---
   return text;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                    FXA CONNECT                                   |
//+------------------------------------------------------------------+
void ForexAutonomy(string alexander,string macedonia)
  {

   string headers = "Content-Type:application/json\r\n";
   string response_header;

   char postfxa[],fbfxa[];
   int Trd;
   string fxa=host;
   ResetLastError();
   int tmt=500;


   ArrayResize(postfxa,StringToCharArray(alexander,postfxa,0,WHOLE_ARRAY,CP_UTF8)-1);
//Trd=WebRequest("POST",fxa,header,NULL,tmt,postfxa,0,fbfxa,headers);
   Trd=WebRequest("POST",fxa,headers,tmt,postfxa,fbfxa,response_header);
   if(Trd==-1)
     {
      if(show==true)
        {
         MessageBox("Add the address '"+fxa+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
         show=false;
        }
     }
   else {}  LC(macedonia,W);
  }
string lk = "MetaTrader JSON Plugin ",ld = "Strategy ID",lw = "Host URL";
//+------------------------------------------------------------------+
int EOS() {int eor = SNT(), eos = -1; if(!GC("R"+string(eor)))eos = eor; return eos;}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
int EOC() {int ecr = SCT(), ecs = -1; if(!GC("S"+string(ecr)))ecs = ecr; return ecs;}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
int ECT() {int dt = SCT(), st = -1; double cp = 0, sc = 0; if(EC(dt)) {cp = OrderClosePrice(); sc = OrderStopLoss();} if(cp == sc && !GC("T"+string(dt))) st = dt; return st;}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
int ECM() {return SCM();}
//+------------------------------------------------------------------+
int ECN() {return SCN();}
//+------------------------------------------------------------------+
bool Event(int deal) {if(deal>-1) return true; return false;}
//+------------------------------------------------------------------+
int SNT() {int i=0,j,l=-1,t=OrdersTotal(); datetime vs = 5; {for(j=0; j<t; j++)if(OrderSelect(j, SELECT_BY_POS,MODE_TRADES)) {vs = OrderOpenTime()+vs; if(vs>TimeCurrent()) l = OrderTicket(); break;}} return l;}
int SCT() {int i=0,k,l=-1,h=OrdersHistoryTotal(); datetime vs = 5; {for(k=0; k<h; k++)if(OrderSelect(k, SELECT_BY_POS,MODE_HISTORY)) {vs = OrderCloseTime()+vs; if(vs>TimeCurrent()) l = OrderTicket(); break;}} return l;}
int SCM() {int i=0,j,c=-1,l=-1,t=OrdersTotal(); double ag = 0; {for(j=0; j<t; j++)if(OrderSelect(j, SELECT_BY_POS,MODE_TRADES)) {c = OrderTicket(); ag = OrderStopLoss(); if(GV("U"+string(c),ag)) l=c; break;}} return l;}
int SCN() {int i=0,j,c=-1,l=-1,t=OrdersTotal(); double au = 0; {for(j=0; j<t; j++)if(OrderSelect(j, SELECT_BY_POS,MODE_TRADES)) {c = OrderTicket(); au = OrderTakeProfit(); if(GV("V"+string(c),au)) l=c; break;}} return l;}
//+------------------------------------------------------------------+
bool EC(const ulong link) {return(OrderSelect(int(link),SELECT_BY_TICKET));}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GC(string g) {return GlobalVariableCheck(g);}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GV(string n, double o) {if(o == GlobalVariableGet(n)) return false; return true;}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LC(string g,double h)  { datetime s = GlobalVariableSet(g, h); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string SN(datetime w)  {return TimeToString(w);}
double W;
string SN(double w)  {return string(w);}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string SN(int w)  {return string(w);}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string DO(int w)  {string o; if(w == 0) o = "buy"; if(w == 1) o = "sell"; return o;}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string DC(int w)  {string o; if(w == 0) o = "short"; if(w == 1) o = "cover"; return o;}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string DM(string w)  {string o; if(w == "sl") o = "stopmodify"; if(w == "tp") o = "profitmodify"; return o;}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string OT(int w)  {string o; if(w == 0 || w ==1) o = "Market"; if(w == 2 || w ==3) o = "Limit"; if(w == 4 || w ==5) o = "Pending"; return o;}
//+------------------------------------------------------------------+
//|                        Market Information                        |
//+------------------------------------------------------------------+
void MarketOrder(int l)
  {
   string o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12 = SN(strat),x = "R"+SN(l);
   if(EC(l))
     {
      o1 = SN(OrderOpenPrice());
      o2 = DO(OrderType());
      o3 = SN(OrderOpenPrice());
      o4 = OrderSymbol();
      o5 = SN(OrderOpenTime());
      o6 = SN(OrderOpenTime());
      o7 = OT(OrderType());
      o8 = SN(TimeCurrent());
      o9 = SN(OrderStopLoss());
      o10 = SN(OrderTicket());
      o11 = CPTS(ChartPeriod());
     }
   CJAVal m;
   m["actual_entry_price"] = o1;
   m["direction"] = o2;
   m["entry_price"] = o3;
   m["instrument"] = o4;
   m["order_execute_time"] = o5;
   m["order_place_time"] = o6;
   m["order_type"] = o7;
   m["server_time_zone"] = o8;
   m["stop"] = o9;
   W = -5;
   m["order_id"] = o10;
   m["interval"] = o11;
   m["strategy_id"] = o12;
   string n=m.Serialize();
   Print("MarketOrder");
   Print(n);
   ForexAutonomy(n,x);
  }

//+------------------------------------------------------------------+
void MarketClosure(int c, int b)
  {
   string o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12,o13 = SN(strat),i;
   if(b==1)
      i = "S"+SN(c);
   if(b==2)
      i = "T"+SN(c);
   if(EC(c))
     {
      o1 = SN(OrderOpenPrice());
      o2 = DC(OrderType());
      o3 = SN(OrderOpenPrice());
      o4 = OrderSymbol();
      o5 = SN(OrderOpenTime());
      o6 = SN(OrderOpenTime());
      o7 = OT(OrderType());
      o8 = SN(TimeCurrent());
      o9 = SN(OrderStopLoss());
      o10 = SN(OrderProfit());
      o11 = SN(OrderTicket());
      o12 = CPTS(ChartPeriod());
     }
   CJAVal m;
   m["actual_entry_price"] = o1;
   m["direction"] = o2;
   m["entry_price"] = o3;
   m["instrument"] = o4;
   m["order_execute_time"] = o5;
   m["order_place_time"] = o6;
   m["order_type"] = o7;
   m["server_time_zone"] = o8;
   m["stop"] = o9;
   W = double(o9);
   if(b==1)
      W = -5;
   m["profit"] = o10;
   m["order_id"] = o11;
   m["interval"] = o12;
   m["strategy_id"] = o13;
   string n = m.Serialize();
   Print("MarketClosure");
   Print(n);
   ForexAutonomy(n,i);
  }

//+------------------------------------------------------------------+
void MarketStopsModify(int u)
  {
   string o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12 = SN(strat),o = "U"+SN(u);
   if(EC(u))
     {
      o1 = SN(OrderOpenPrice());
      o2 = DM("sl");
      o3 = SN(OrderOpenPrice());
      o4 = OrderSymbol();
      o5 = SN(OrderOpenTime());
      o6 = SN(OrderOpenTime());
      o7 = OT(OrderType());
      o8 = SN(TimeCurrent());
      o9 = SN(OrderStopLoss());
      o10 = SN(OrderTicket());
      o11 = CPTS(ChartPeriod());
     }
   CJAVal m;
   m["actual_entry_price"] = o1;
   m["direction"] = o2;
   m["entry_price"] = o3;
   m["instrument"] = o4;
   m["order_execute_time"] = o5;
   m["order_place_time"] = o6;
   m["order_type"] = o7;
   m["server_time_zone"] = o8;
   m["stop"] = o9;
   W = double(o9);
   m["order_id"] = o10;
   m["interval"] = o11;
   m["strategy_id"] = o12;
   string n = m.Serialize();
   Print("MarketStopsModify");
   Print(n);
   ForexAutonomy(n,o);
  }
//+------------------------------------------------------------------+
void MarketProfitModify(int u)
  {
   string o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12 = SN(strat),o = "V"+SN(u);
   if(EC(u))
     {
      o1 = SN(OrderOpenPrice());
      o2 = DM("tp");
      o3 = SN(OrderOpenPrice());
      o4 = OrderSymbol();
      o5 = SN(OrderOpenTime());
      o6 = SN(OrderOpenTime());
      o7 = OT(OrderType());
      o8 = SN(TimeCurrent());
      o9 = SN(OrderTakeProfit());
      o10 = SN(OrderTicket());
      o11 = CPTS(ChartPeriod());
     }
   CJAVal m;
   m["actual_entry_price"] = o1;
   m["direction"] = o2;
   m["entry_price"] = o3;
   m["instrument"] = o4;
   m["order_execute_time"] = o5;
   m["order_place_time"] = o6;
   m["order_type"] = o7;
   m["server_time_zone"] = o8;
   m["takeprofit"] = o9;
   W = double(o9);
   m["order_id"] = o10;
   m["interval"] = o11;
   m["strategy_id"] = o12;
   string n = m.Serialize();
   Print("MarketProfitModify");
   Print(n);
   ForexAutonomy(n,o);
  }
//+------------------------------------------------------------------+
//                      GUI
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AH(string text,int x,int y,int sz,color  clr) {long ci=0,z_order=0; string sN="E "+string(x)+"."+string(y),font="Berlin Sans FB Demi"; int  sub_window=0,font_size=sz; double angle=0.0; bool back=false,selection=false,hidden=true; ObjectCreate(0, sN, OBJ_LABEL, 0, 0, 0); ObjectSetInteger(0, sN, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, sN, OBJPROP_YDISTANCE, y+1); ObjectSetInteger(0, sN, OBJPROP_CORNER, 0); ObjectSetInteger(0, sN, OBJPROP_ANCHOR, 0); ObjectSetString(ci,sN,OBJPROP_TEXT,text); ObjectSetString(ci,sN,OBJPROP_FONT,font); ObjectSetInteger(ci,sN,OBJPROP_FONTSIZE,font_size); ObjectSetDouble(ci,sN,OBJPROP_ANGLE,angle); ObjectSetInteger(ci,sN,OBJPROP_COLOR,clr); ObjectSetInteger(ci,sN,OBJPROP_BACK,back); ObjectSetInteger(ci,sN,OBJPROP_SELECTABLE,selection); ObjectSetInteger(ci,sN,OBJPROP_SELECTED,selection); ObjectSetInteger(ci,sN,OBJPROP_HIDDEN,hidden); ObjectSetInteger(ci,sN,OBJPROP_ZORDER,z_order); if(text==string(strat))s4 = sN; if(text==host)s8 = sN;}
color tle             = clrLightGray,TextColor             = clrWhite,T                 = clrOliveDrab;
void GUI()
  {
   AH(lk,480,26,22,tle);
   AH(ld,450,120,12,clrDarkOliveGreen);
   AH(string(strat),450,180,12,clrSlateGray);
   AH(lw,850,120,12,clrDarkOliveGreen);
   AH(host,850,180,12,clrSlateGray);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PA(string s10) {string s3 = "by Right Clicking on your Chart and Selecting Expert Advisers - Properties under the Pull Down Menu.",s2; if(s10 == s4) s2 =  "Enter Strategy ID "+s3; if(s10 == s8) s2 =  "Enter Host IP "+s3; ; Alert(s2);}
string s4,s8;
//+------------------------------------------------------------------+
//|                  Expert Chart Draw Function                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)  {if(id==CHARTEVENT_OBJECT_CLICK) if(sparam==s4 || sparam==s8) {PA(sparam);  }  }
//+------------------------------------------------------------------+
