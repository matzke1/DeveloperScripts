all: adjust-nvbl

adjust-nvbl: adjust-nvbl.C
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $<

.PHONY: install
install: adjust-nvbl
	chown root:root $^
	chmod 4711 $^
