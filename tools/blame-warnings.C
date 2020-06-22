// Compile as:
//   c++ -Wall -g -I$BOOST_ROOT/include -o blame-warnings blame-warnings.C -Wl,-rpath,$BOOST_ROOT/lib -L$BOOST_ROOT/lib -lboost_filesystem -lboost_regex
//
// where c++ is your C++14 or better compiler, and $BOOST_ROOT is the installation root for Boost compiled with that same compiler.

#include <array>
#include <boost/algorithm/string/predicate.hpp>
#include <boost/algorithm/string/trim.hpp>
#include <boost/filesystem.hpp>
#include <boost/format.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/regex.hpp>
#include <cstdio>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

struct Settings {
    bool verbose;                                       // print the shell commands that are run
    bool debug;                                         // show some additional debug-level output
    bool showHistogram;                                 // show authors and number of warnings for each, at end of output
    bool showDups;                                      // show blame even when it would be the same as the previous warning
    boost::filesystem::path gitRepo;                    // location of Git repository (anywhere in the repo)

    Settings()
        : verbose(false), debug(false), showHistogram(true), showDups(true), gitRepo(".") {}
};

static Settings gSettings;

static void
help() {
    std::cout <<"blame-warnings: Help is not written yet. Use the source, Luke.\n"; // FIXME
}

using FileNames = std::set<boost::filesystem::path>;

// Translations from an email address to a name. We only worry about the part before the "@" since these are unique enough
// already. The reason we don't use Git is because the names in the commit logs are as varied as their email addresses, and we
// need something more uniform, especially in order to create a meaningful histogram.
static std::map<std::string, std::string> gNameTranslations = {
    {"aananthakris1",                   "Sriram Aananthakrishnan"},
    {"aananthakris1",                   "Sriram Aananthakrishnan"},
    {"adrian",                          "Adrian Prantl"},
    {"adrian.prantl",                   "Adrian Prantl"},
    {"andreas",                         "Andreas Sæbjørnsen"},
    {"andreas",                         "Andreas Sæbjørnsen"},
    {"andreas.saebjoernsen",            "Andreas Sæbjørnsen"},
    {"asplund1",                        "Josh Asplund"},
    {"asplund1",                        "Josh Asplund"},
    {"atomb",                           "Aaron Tomb"},
    // {"bauer25", "bauer25"}, // FIXME: lookup name from llnl.gov phone book
    {"bhat2",                           "Akshatha Bhat"},
    {"bill.hoffman",                    "Bill Hoffman"},
    {"bronevet",                        "Greg Bronevetsky"},
    {"bronevetsky",                     "Greg Bronevetsky"},
    {"brown223",                        "Matt Brown"},
    {"brown22",                         "Matt Brown"},
    {"brown",                           "Matt Brown"},
    {"cfc",                             "Cory Cohen"},
    {"chabbi1",                         "Milind Chabbi"},
    {"charlesareynolds",                "Charles Reynolds"},
    {"chu24",                           "Jonathan Chu"},
    {"chunhualiao",                     "Chunhua Liao"},
    {"ci",                              "CI System"},
    {"collingbourne2",                  "Peter Collingbourne"},
    {"cong",                            "Cong Hou"},
    {"dagit",                           "Jason Dagit"},
    {"doubleotoo",                      "Justin Too"},
    {"dquinlan",                        "Dan Quinlan"},
    {"driscoll6",                       "Michael Driscoll"},
    {"dxnguyen",                        "Dung Nguyen"},
    {"ebner",                           "Dietmar Ebner"},
    {"eschwartz",                       "Ed Schwartz"},
    {"faizurahman",                     "Faizur Rahman"},
    {"florian.andrefranc.mayer",        "Florian Mayer"},
    {"frye5",                           "Justin Frye"},
    {"georgevulov",                     "George Vulov"},
    {"gergo",                           "Gergo Barany"},
    // {"hamilton37", "hamilton37"}, // FIXME: lookup name from llnl.gov phone book
    // {"heller9", "heller9"}, // FIXME: lookup name from llnl.gov phone book
    {"hoffman34",                       "Michael Hoffman"},
    {"horie",                           "Michihiro Horie"},
    {"hou1",                            "Cong Hou"},
    {"hou_cong",                        "Cong Hou"},
    {"hudson-rose",                     "ROSE Manager"},
    // {"jak", "jak"}, // FIXME: anyone know who this is?
    {"jan.lehr",                        "Jan Lehr"},
    {"jasper3",                         "Mark Jasper"},
    {"joshasplund",                     "Josh Asplund"},
    {"joshuata",                        "Josh Asplund"},
    {"jp.lehr",                         "Jan Lehr"},
    {"justin",                          "Justin Too"},
    {"keasler",                         "Jeff Keasler"},
    {"kelly64",                         "Sam Kelly"},
    {"kgs1",                            "Kamal Sharma"},
    {"king40",                          "Alden King"},
    {"king84",                          "Alden King"},
    {"konstantinid1",                   "Athanasios Konstantinidis"},
    {"leek2",                           "Jim Leek"},
    {"leo",                             "Chunhua Liao"},
    {"liao6",                           "Chunhua Liao"},
    {"liaoch",                          "Chunhua Liao"},
    {"liao",                            "Chunhua Liao"},
    {"lin32",                           "Pei-Hung Lin"},
    // {"ma23", "Ma"}, // FIXME: lookup name from llnl.gov phone book
    {"marc.jasper",                     "Marc Jasper"},
    {"markus",                          "Markus Schordan"},
    {"matt",                            "Matthew Sottile"},
    {"matzke1",                         "Robb Matzke"},
    {"matzke",                          "Robb Matzke"},
    {"mdhoffman",                       "Michael Hoffman"},
    {"michael",                         "Michael Hoffman"},
    {"Michihiro Horie",                 "Michihiro Horie"},
    {"mille121",                        "Phil Miller"},
    {"miller256",                       "Phil Miller"},
    {"m.schordan",                      "Markus Schordan"},
    {"nathan",                          "Nathan Matzke"},
    {"negara1",                         "Stanislav Negara"},
    {"nguyenthanh1",                    "Tan Nguyen"},
    {"panas2",                          "Thomas Panas"},
    {"panas",                           "Thomas Panas"},
    {"pcc03",                           "Peter Collingbourne"},
    {"peihunglin",                      "Pei-Hung Lin"},
    {"peter",                           "Peter Collingbourne"},
    {"peter.pirkelbauer",               "Peter Pirkelbauer"},
    {"peterp",                          "Peter Pirkelbauer"},
    {"pgc1",                            "Philippe Charles"},
    {"phlin",                           "Pei-Hung Lin"},
    {"pinnow2",                         "Nathan Pinnow"},
    {"pirkelbauer2",                    "Peter Pirkelbauer"},
    {"pirkelbauer",                     "Peter Pirkelbauer"},
    {"pouchet",                         "Louis-Noel Pouchet"},
    {"quinlan1",                        "Dan Quinlan"},
    {"qyi",                             "Qing Yi"},
    {"rahman2",                         "Faizur Rahman"},
    {"rasmus",                          "Craig Rasmussen"},
    {"rasmussen17",                     "Craig Rasmussen"},
    {"reus1",                           "Jim Reus"},
    {"reus",                            "Jim Reus"},
    {"reynolds12",                      "Charles Reynolds"},
    {"rose-mgr",                        "ROSE Manager"},
    {"rose",                            "ROSE Manager"},
    {"roup.michael",                    "Michael Roup"},
    {"royuelaalcaz1",                   "Sara Alcazar"},
    {"saebjornsen1",                    "Andreas Sæbjørnsen"},
    {"sara.royuela",                    "Sara Alcazar"},
    {"schordan1",                       "Markus Schordan"},
    {"schordan",                        "Markus Schordan"},
    // {"schreiner", "schreiner"}, // FIXME: anyone know who this is?
    {"schroder3",                       "Simon Schroder"},
    {"scott",                           "Scott Warren"},
    {"sharma9",                         "Kamal Sharma"},
    {"simon.schroeder",                 "Simon Schroeder"},
    {"sriram",                          "Sriram Aananthakrishnan"},
    // {"stutsman1", "stutsman1"}, // FIXME: lookup name from llnl.gov phone book
    {"sujank",                          "Sujan Khadka"},
    {"too1",                            "Justin Too"},
    {"tristan",                         "Tristan Vanderbruggen"},
    {"utke",                            "Jean Utke"},
    {"vanderbrugge1",                   "Tristan Vanderbruggen"},
    {"vanderbruggentristan",            "Tristan Vanderbruggen"},
    {"vanka1",                          "Rajeshwar Vanka"},
    {"vpavlu",                          "Viktor Pavlu"},
    {"vulov1",                          "Viktor Pavlu"},
    {"wang72", "wang"},
    {"willcock2",                       "Jeremiah Willcock"},
    {"willcock",                        "Jeremiah Willcock"},
    {"yi7",                             "Qing  Yi"},
    // {"yuan5", "yuan5"}, // FIXME: lookup name from llnl.gov phone book
    {"zack.galbreath",                  "Zack Galbreath"},

};

// Parse the command line to initialize gSettings
static void
parseCommandLine(int argc, char *argv[]) {
    for (int i = 1; i < argc; ++i) {
        if (std::string("-h") == argv[i] || std::string("--help") == argv[i]) {
            help();
            exit(0);
        } else if (std::string("--verbose") == argv[i]) {
            gSettings.verbose = true;
        } else if (std::string("--quiet") == argv[i] || std::string("--no-verbose") == argv[i]) {
            gSettings.verbose = false;
        } else if (std::string("--debug") == argv[i]) {
            gSettings.debug = true;
        } else if (std::string("--histogram") == argv[i]) {
            gSettings.showHistogram = true;
        } else if (std::string("--no-histogram") == argv[i]) {
            gSettings.showHistogram = false;
        } else if (std::string("--duplicates") == argv[i]) {
            gSettings.showDups = true;
        } else if (std::string("--no-duplicates") == argv[i]) {
            gSettings.showDups = false;
        } else if (boost::starts_with(argv[i], "--repo=")) {
            gSettings.gitRepo = std::string(argv[i]).substr(7);
        } else {
            std::cerr <<argv[0] <<": unrecognized command-line argument: \"" <<argv[i] <<"\"\n";
            exit(1);
        }
    }
}

// Convert an email address to a name using the global gNameTranslations table from above.
static std::string
emailToName(const std::string &email) {
    std::string user;
    size_t at = email.find('@');
    if (at != std::string::npos) {
        user = email.substr(0, at);
    } else {
        user = email;
    }

    auto found = gNameTranslations.find(user);
    if (gNameTranslations.end() == found)
        return email;
    return found->second;
}

// Run a command and read all its standard output, returned as an array of lines including line terminators.
// FIXME: code injection vulnerability since we're using the shell to parse the command
static std::vector<std::string>
execute(const std::string &cmd) {
    struct Resources {
        FILE *cmdOutput = nullptr;
        char *line = nullptr;
        ~Resources() {
            if (cmdOutput)
                pclose(cmdOutput);
            if (line)
                free(line);
        }
    } r;
    std::vector<std::string> retval;
    if (gSettings.verbose)
        std::cerr <<"+ " <<cmd <<"\n";
    if ((r.cmdOutput = popen(cmd.c_str(), "r"))) {
        size_t n = 0;
        while (getline(&r.line, &n, r.cmdOutput) > 0)
            retval.push_back(r.line);
    }
    return retval;
}

// Run a command and return its first line of output without any trailing line termination.
static std::string
execute1(const std::string &cmd) {
    auto output = execute(cmd);
    return output.empty() ? std::string() : boost::trim_right_copy(output.front());
}

// Get all file names in the Git repository
static FileNames
findAllGitFiles() {
    FileNames retval;
    gSettings.gitRepo = execute1("git -C '" + gSettings.gitRepo.string() + "' rev-parse --show-toplevel");
    for (auto line: execute("git -C '" + gSettings.gitRepo.string() + "' ls-tree --full-tree -r --name-only HEAD")) {
        auto fullName = gSettings.gitRepo / boost::filesystem::path(boost::trim_right_copy(line));
        if (gSettings.debug)
            std::cerr <<"debug: found repository file: " <<fullName <<"\n";
        retval.insert(fullName);
    }
    return retval;
}

// Given a file name, return the number of components. For example, "/foo/bar" has three components ("/", "foo", and "bar")
// while "foo/bar" has two components ("foo" and "bar").
static size_t
nComponents(boost::filesystem::path name) {
    size_t retval = 0;
    while (!name.filename().empty()) {
        ++retval;
        name = name.parent_path();
    }
    return retval;
}

// Given a file name, return the last N components of the name.  For instance, the last two components of "./foo/bar/baz.C"
// are "bar/baz.C".  If the name doesn't contain N components then return the empty name.
static boost::filesystem::path
lastComponents(boost::filesystem::path name, size_t nComponents) {
    boost::filesystem::path retval;
    for (size_t i = 0; i < nComponents; ++i) {
        if (name.empty())
            return {};
        retval = name.filename() / retval;
        name = name.parent_path();
    }
    return retval;
}

// Given a file name from a warning message, convert it to a file name relative to the root of the Git repository. The problem
// we're trying to solve here is that the build system runs the compilers in various working directories and the compiler
// warnings have the file names relative to that CWD. We can't rely on the build system to say what the CWD was.
//
// So what we do is we start with just the base name of the warning file and see if we can find a unique matching base name in
// the Git repository. If so, we're done. If nothing matched then we're also done--it was probably a warning in a generated
// file. Otherwise, we look at the base name plus the previous component, then base name plus previous two components,
// etc. until we get a unique match, no matches, or we run out of components.
//
// If we can determine the Git file name then we return it, otherwise we return an empty file name.
static boost::filesystem::path
translateToGitFile(const boost::filesystem::path &name, const FileNames &gitFiles) {
    const size_t n = nComponents(name);
    for (size_t i = 1; i <= n; ++i) {
        boost::filesystem::path key = lastComponents(name, i);
        FileNames found;
        for (const boost::filesystem::path &gitFile: gitFiles) {
            if (lastComponents(gitFile, i) == key)
                found.insert(gitFile);
        }
        if (found.empty())
            return {};
        if (found.size() == 1)
            return *found.begin();
    }
    return {};
}

struct Commit {
    std::string hash;
    std::string email;
    std::string date;
    std::string name;
};

// Git blame for a file. Returns a vector, one element per line, each of which describes who made the change. Since
// line numbers emitted by compilers are one-origin, the first item of the vector is unused.
static std::vector<Commit>
gitBlame(const boost::filesystem::path &fileName) {
    std::vector<Commit> retval(1, Commit());
    //                SHA1                   email       date
    boost::regex re("^(\\^?[0-9a-f]+)\\s.*?\\(<(.*?)>\\s+([12]\\d\\d\\d-\\d\\d-\\d\\d)");
    size_t lineNumber = 0;
    for (auto &line: execute("git -C '" + gSettings.gitRepo.string() + "' blame -e -f -w '" + fileName.string() + "'")) {
        Commit commit;
        ++lineNumber;
        boost::smatch found;
        if (boost::regex_search(line, found, re)) {
            commit.hash = found.str(1);
            commit.date = found.str(3);
            if (boost::starts_with(commit.hash, "^")) {
                commit.name = "initial commit";
            } else {
                commit.email = found.str(2);
                commit.name = emailToName(commit.email);
            }
            retval.push_back(commit);
        } else {
            commit.email = "unknown";
            retval.push_back(commit);
        }
    }
    return retval;
}

int main(int argc, char *argv[]) {
    parseCommandLine(argc, argv);
    FileNames gitFiles = findAllGitFiles();
    std::map<boost::filesystem::path, std::vector<Commit>> allBlame;
    std::map<std::string /*author*/, size_t /*count*/> histogram;

    // Read standard input, and for each line recognized as a compiler warning or error message, obtain information about which
    // author possibly caused the warning or error.
    boost::filesystem::path prevWarningFileName;
    size_t prevWarningLineNumber = 0;
    boost::regex ansiRe("\\033\\[[0-9;]*[mK]");
    boost::regex warningRe("(.*?):([0-9]+)(:[0-9]+)?: (warning|error):");
    while (std::cin) {
        std::string line;
        std::getline(std::cin, line);
        std::cout <<line <<"\n";
        line = boost::regex_replace(line, ansiRe, "");

        boost::smatch foundWarning;
        if (!boost::regex_search(line, foundWarning, warningRe))
            continue;
        boost::filesystem::path warningFileName = foundWarning.str(1);
        size_t warningLineNumber = boost::lexical_cast<size_t>(foundWarning.str(2));

        // Sometimes the compiler generates multiple warnings per line of code, all complaining about the same thing. For
        // instance, GCC generates one line per unhandled enum of a "switch" statement, while LLVM generates just one
        // line. Other times there are actually legitimate different warnings per line. In any case, skip assigning blame for
        // the same line more than once in order to slightly reduce the redundant information in the output.
        if (!gSettings.showDups && warningFileName == prevWarningFileName && warningLineNumber == prevWarningLineNumber) {
            if (gSettings.debug)
                std::cerr <<"debug: same file and line as previous warning\n";
            continue;
        }
        prevWarningFileName = warningFileName;
        prevWarningLineNumber = warningLineNumber;

        // We found a warning or error, so lay some blame. First we need to find the Git file that corresponds to the file
        // name given in the compiler output. This is complicated by the fact that the build system often runs the compiler
        // in different directories than the source code.
        boost::filesystem::path gitFileName = translateToGitFile(warningFileName, gitFiles);
        if (gitFileName.empty()) {
            if (gSettings.debug)
                std::cerr <<"debug: cannot resolve " <<warningFileName <<" to a Git file\n";
            ++histogram.insert(std::make_pair("unresolved file name", size_t(0))).first->second;
            continue;
        }
        
        // Get the git-blame output for this file if we don't have it yet.
        auto fileBlame = allBlame.find(gitFileName);
        if (allBlame.end() == fileBlame)
            fileBlame = allBlame.insert(std::make_pair(gitFileName, gitBlame(gitFileName))).first;

        // Print an additional line after the warning message that lays the blame on a particular author's commit.
        if (warningLineNumber >= fileBlame->second.size()) {
            if (gSettings.debug)
                std::cerr <<"debug: no blame could be found for " <<gitFileName <<" line " <<warningLineNumber <<"\n";
            ++histogram.insert(std::make_pair("blame failure", size_t(0))).first->second;
            continue;
        }
        const Commit &commit = fileBlame->second[warningLineNumber];
        if (commit.hash.empty()) {
            if (gSettings.debug)
                std::cerr <<"debug: cannot parse blame for " <<gitFileName <<" line " <<warningLineNumber <<"\n";
            ++histogram.insert(std::make_pair("blame failure", size_t(0))).first->second;
        } else {
            std::cout <<"blamed on " <<commit.name <<" <" <<commit.email <<"> commit " <<commit.hash <<" from " <<commit.date <<"\n";
            ++histogram.insert(std::make_pair(commit.name, size_t(0))).first->second;
        }
    }

    if (gSettings.showHistogram && !histogram.empty()) {
        std::cout <<"Warnings and errors per author:\n";
        std::vector<std::pair<std::string, size_t>> sorted(histogram.begin(), histogram.end());
        std::sort(sorted.begin(), sorted.end(), [](auto &a, auto &b) { return a.second > b.second; });
        for (auto record: sorted)
            std::cout <<boost::format("\t%5d %s\n") % record.second % record.first;
    }
}
