SUBDIRS = etc win32 src

default: all

32:
	CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x86
	$(MAKE) /f Makefile.mak opensc.msi PLATFORM=x86
	MOVE win32\OpenSC.msi OpenSC_win32.msi

64:
	CALL "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x86_amd64
	$(MAKE) /f Makefile.mak opensc.msi
	MOVE win32\OpenSC.msi OpenSC_win64.msi

opensc.msi:
	$(MAKE) /f Makefile.mak all"
	@cmd /c "cd win32 && $(MAKE) /nologo /f Makefile.mak opensc.msi"

#opensc.msi:
#	$(MAKE) /f Makefile.mak all OPENSSL_DEF=/DENABLE_OPENSSL OPENPACE_DEF=/DENABLE_OPENPACE"
#	@cmd /c "cd win32 && $(MAKE) /nologo /f Makefile.mak opensc.msi OPENSSL_DEF=/DENABLE_OPENSSL OPENPACE_DEF=/DENABLE_OPENPACE"

all clean::
	@for %i in ( $(SUBDIRS) ) do @cmd /c "cd %i && $(MAKE) /nologo /f Makefile.mak $@"
