// Compile as:
//   c++ -Wall -g -I$BOOST_ROOT/include -o blame-warnings blame-warnings.C -Wl,-rpath,$BOOST_ROOT/lib -L$BOOST_ROOT/lib -lboost_filesystem -lboost_regex -lboost_system
//
// where c++ is your C++14 or better compiler, and $BOOST_ROOT is the installation root for Boost compiled with that same compiler.

#include <array>
#include <boost/algorithm/string/predicate.hpp>
#include <boost/algorithm/string/split.hpp>
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
    bool verbose = false;                               // print the shell commands that are run?
    bool debug = false;                                 // show some additional debug-level output?
    bool showHistogram = true;                          // show authors and number of warnings for each, at end of output?
    bool showDups = true;                               // show blame even when it would be the same as the previous warning?
    boost::filesystem::path gitRepo = ".";              // location of Git repository (anywhere in the repo)
    boost::regex highlight;                             // highlight blame line if pattern found in name or email
    bool useColor = true;                               // colored output?
    boost::filesystem::path updateAuthorship;           // update the .authorship file by traversing specified repo path
};

static Settings gSettings;

static void
help() {
    std::cout <<"blame-warnings: Help is not written yet. Use the source, Luke.\n"; // FIXME
}

using FileNames = std::set<boost::filesystem::path>;
using Histogram = std::map<std::string, size_t>;
using Authorship = std::map<boost::filesystem::path, Histogram>;

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
    {"not.committed.yet",               "uncommitted code"},
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

// Name and email of current user
static std::pair<std::string, std::string>
currentUser() {
    std::string email = execute1("git -C '" + gSettings.gitRepo.string() + "' config user.email");
    if (email.empty()) {
        if (const char *s = getenv("USER"))
            email = s;
    }
    return std::make_pair(emailToName(email), email);
}

// Try to figure out the location of the Git repository.
static boost::filesystem::path
findRepository() {
    // First, ask Git if it knows where the repo is. This only works if we're inside the Git repo or the right environment
    // variables are set. If so, we want the top repo, not any submodule, so we recursively look above the returned path for
    // another repo.
    boost::filesystem::path repo = execute1("git rev-parse --show-toplevel 2>/dev/null");
    while (!repo.empty()) {
        boost::filesystem::path parentDir = repo.parent_path();
        if (parentDir.empty())
            return repo;
        boost::filesystem::path parentRepo = execute1("git -C " + parentDir.string() + " rev-parse --show-toplevel 2>/dev/null");
        if (parentRepo.empty())
            return repo;
        repo = parentRepo;
    }

    // Git is clueless, so try autotools. If "configure" was run then it will have created a connfig.status file (it also may
    // have created a config.log but since that's debugging info we shouldn't depend on it still being present).  The
    // config.status file will have a line something like "configured by /home/matzke/rose-wip/rose/configure, generated by GNU
    // Autoconf 2.69," from which we can get the path to the repository assuming that the "configure" script is at the top
    // level.
    boost::filesystem::path dir = boost::filesystem::current_path();
    while (!dir.empty()) {
        boost::filesystem::path configStatus = dir / "config.status";
        boost::regex re("^configured by (.*), generated by GNU Autoconf");
        if (boost::filesystem::exists(configStatus)) {
            std::ifstream in(configStatus.c_str());
            while (in) {
                std::string line;
                std::getline(in, line);
                boost::smatch found;
                if (boost::regex_search(line, found, re))
                    return boost::filesystem::path(found.str(1)).parent_path();
            }
        }
        dir = dir.parent_path();
    }

    return {};
}

// Parse the command line to initialize gSettings
static void
initialize(int argc, char *argv[]) {
    gSettings.useColor = isatty(1);
    gSettings.gitRepo = findRepository();
    bool makeDefaultHighlight = true;

    for (int i = 1; i < argc; ++i) {
        if (std::string("-h") == argv[i] || std::string("--help") == argv[i]) {
            help();
            exit(0);
        } else if (std::string("--verbose") == argv[i]) {
            gSettings.verbose = true;
        } else if (std::string("--quiet") == argv[i] || std::string("--no-verbose") == argv[i]) {
            gSettings.verbose = false;
        } else if (boost::starts_with(argv[i], "--authorship=")) {
            gSettings.updateAuthorship = std::string(argv[i]).substr(13);
        } else if (std::string("--debug") == argv[i]) {
            gSettings.debug = true;
        } else if (std::string("--color=always") == argv[i]) {
            gSettings.useColor = true;
        } else if (std::string("--color=auto") == argv[i]) {
            gSettings.useColor = isatty(1);
        } else if (std::string("--color=never") == argv[i]) {
            gSettings.useColor = false;
        } else if (std::string("--histogram") == argv[i]) {
            gSettings.showHistogram = true;
        } else if (std::string("--no-histogram") == argv[i]) {
            gSettings.showHistogram = false;
        } else if (boost::starts_with(argv[i], "--highlight=")) {
            gSettings.highlight = std::string(argv[i]).substr(12);
            makeDefaultHighlight = false;
        } else if (std::string("--no-highlight") == argv[i]) {
            gSettings.highlight = "";
            makeDefaultHighlight = false;
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

    if (gSettings.gitRepo.empty()) {
        std::cerr <<argv[0] <<": cannot find a Git repository; try using --repo=PATH_TO_REPOSITORY\n";
        exit(1);
    }
    gSettings.gitRepo = execute1("git -C '" + gSettings.gitRepo.string() + "' rev-parse --show-toplevel");
    if (gSettings.debug)
        std::cerr <<"debug: git repository is " <<gSettings.gitRepo <<"\n";

    gNameTranslations["not.committed.yet"] = currentUser().first;

    if (makeDefaultHighlight) {
        std::string myName = currentUser().first;
        if (gSettings.debug)
            std::cerr <<"debug: you are \"" <<myName <<"\"\n";
        if (myName.empty()) {
            gSettings.highlight = "not.committed.yet";
        } else {
            boost::regex specials("[.^$|()\\[\\]{}*+?\\\\]");
            myName = boost::regex_replace(myName, specials, "\\\\&", boost::match_default | boost::format_sed);
            gSettings.highlight = myName + "|uncommitted code";
        }
    }
}

// Get all file names in the Git repository recursively starting at root (which is relative to the root of the Git repo).
static FileNames
findGitFiles(const boost::filesystem::path &root) {
    FileNames retval;
    std::string cmd = "git -C '" + gSettings.gitRepo.string() + "' ls-tree --full-name -r --name-only HEAD '" + root.string() + "'";
    for (auto line: execute(cmd)) {
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

// Build a mapping from file name parts to git file names.  E.g., for a file named "foo/bar/baz" we will create three entries
// in the map: "baz", "bar/baz", and "foo/bar/baz" all pointing to "foo/bar/baz". However, if we later try to add "foo/bbb/baz"
// then the "baz" entry will be erased because it's ambiguous.
using FileNameMap = std::map<boost::filesystem::path /*partial_name*/, boost::filesystem::path /*full_name*/>;
static FileNameMap gFileNameMap;

static void
initializeFileNameMap(const FileNames &gitFiles) {
    gFileNameMap.clear();
    FileNames toErase;
    for (const boost::filesystem::path &fullName: gitFiles) {
        boost::filesystem::path remaining = fullName;
        boost::filesystem::path partial;
        while (!remaining.empty() && remaining != gSettings.gitRepo) {
            partial = remaining.filename() / partial;
            remaining = remaining.parent_path();
            if (!gFileNameMap.insert(std::make_pair(partial, fullName)).second)
                toErase.insert(partial);
        }
    }
    for (const boost::filesystem::path &partial: toErase)
        gFileNameMap.erase(partial);
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
        auto found = gFileNameMap.find(key);
        if (found != gFileNameMap.end())
            return found->second;
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
    //                SHA1                   email       date                         rest
    boost::regex re("^(\\^?[0-9a-f]+)\\s.*?\\(<(.*?)>\\s+([12]\\d\\d\\d-\\d\\d-\\d\\d)(.*)");
    boost::regex reblameRe("// blame (.*)");
    size_t lineNumber = 0;
    for (auto &line: execute("git -C '" + gSettings.gitRepo.string() + "' blame -e -f -w '" + fileName.string() + "'")) {
        Commit commit;
        ++lineNumber;
        boost::smatch found;
        if (boost::regex_search(line, found, re)) {
            commit.hash = found.str(1);
            commit.date = found.str(3);

            boost::smatch reblame;
            if (boost::regex_search(found.str(4), reblame, reblameRe)) {
                commit.name = emailToName(boost::trim_copy(reblame.str(1)));
                commit.email = "reblamed";
            } else if (boost::starts_with(commit.hash, "^")) {
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

// Write authorship histogram to the ".authorship" file at the root of the Git repository. Each line has
// three TAB-separted fields: number of lines, author name, file name w.r.t. the Git repo root.
static void
updateAuthorship(const FileNames &files) {
    auto fileName = gSettings.gitRepo / ".authorship.partial";
    std::ofstream out(fileName.c_str());
    if (!out) {
        std::cerr <<"blame-warnings: cannot write to " <<fileName <<"\n";
        exit(1);
    }

    Histogram histogram;
    for (const boost::filesystem::path &file: files) {
        Histogram locCounts;
        for (auto &commit: gitBlame(file))
            ++locCounts[commit.name];
        for (auto &node: locCounts)
            out <<node.second <<"\t" <<node.first <<"\t" <<boost::filesystem::relative(file, gSettings.gitRepo).string() <<"\n";
    }

    out.close();
    boost::filesystem::rename(fileName, gSettings.gitRepo / ".authorship");
}

// If there's an ".authorship" file at the top of the git repo, then read it. The return value is a map
// indexed by absolute file name and whose value is a histogram of lines per author name.
static Authorship
readAuthorship() {
    Authorship retval;
    std::ifstream in((gSettings.gitRepo / ".authorship").c_str());
    while (in) {
        std::string line;
        std::getline(in, line);
        std::vector<std::string> fields;
        boost::split(fields, line, [](char ch) { return '\t' == ch; });
        if (fields.size() >= 3) {
            size_t nLines = boost::lexical_cast<size_t>(fields[0]);
            const std::string &author = fields[1];
            boost::filesystem::path fileName = gSettings.gitRepo / fields[2];
            retval[fileName][author] += nLines;
        }
    }
    return retval;
}

// Count lines of code per author for the specified files.  This info comes from the .authorship file if present.
static Histogram
locPerAuthor(const Authorship &authorship, const FileNames &files) {
    Histogram retval;
    for (const boost::filesystem::path &file: files) {
        auto found = authorship.find(file);
        if (found != authorship.end()) {
            for (const auto &node: found->second)
                retval[node.first] += node.second;
        }
    }
    return retval;
}

// Scans the specified line of compiler or build system output and tries to figure out which source files from the Git
// repository are being accessed. Adds those files to the specified set.
static void
findMentionedFiles(const std::string &line, FileNames &files, const FileNames &gitFiles) {
    static std::vector<std::string> sourceExtensions{".C", ".cpp", ".cc", ".h", ".hpp", ".hh", ".c"};

    // It's hard to tell what might be a file name, so we're pretty lax here. The translateToGitFile will tell us whether the thing
    // we matched corresponds to a unique file in the Git repo.
    boost::regex fileNameRe("([-+/_.a-zA-Z0-9]+)");
    boost::filesystem::path gitFile;
    for (boost::sregex_iterator iter(line.begin(), line.end(), fileNameRe); iter != boost::sregex_iterator(); ++iter) {
        boost::filesystem::path fileName = iter->str(1); // at this point, only a potential file name
        gitFile = translateToGitFile(fileName, gitFiles);

        // ROSE's autotools build system prints the /target/ of the makefile rule instead of the inputs. Therefore, when
        // compiling a C file like "foo.c" the build system will print something like "CXX finaltarget-foo.lo". So we need to
        // extract the final part and then also try various common source file extensions as well. This won't handle cases where
        // the source file itself has hyphens, but I don't think that happens often.
        if (gitFile.empty()) {
            boost::regex re("(.*/)?([+_a-zA-Z0-9]+-)([+_a-zA-Z0-9]+)\\.lo");
            boost::smatch found;
            if (boost::regex_match(fileName.string(), found, re)) {
                for (size_t i = 0; i < sourceExtensions.size() && gitFile.empty(); ++i) {
                    auto name = boost::filesystem::path(found.str(1)) / (found.str(3) + sourceExtensions[i]);
                    gitFile = translateToGitFile(name, gitFiles);
                }
            }
        }

        // ROSE's autotools build also sometimes prints .o files instead of source files.
        if (gitFile.empty()) {
            boost::regex re("(.*)\\.l?o");
            boost::smatch found;
            if (boost::regex_match(fileName.string(), found, re)) {
                for (size_t i = 0; i < sourceExtensions.size() && gitFile.empty(); ++i) {
                    boost::filesystem::path name(found.str(1) + sourceExtensions[i]);
                    gitFile = translateToGitFile(name, gitFiles);
                }
            }
        }

        if (!gitFile.empty()) {
            if (gSettings.debug)
                std::cerr <<"debug: found mentioned file " <<gitFile <<"\n";
            files.insert(gitFile);
            continue;
        }
    }
}

// Converts a set of file names to the directories that contain them.
static FileNames
directories(const FileNames &fileNames) {
    FileNames retval;
    for (auto &fileName: fileNames)
        retval.insert(fileName.parent_path());
    retval.erase(boost::filesystem::path());
    return retval;
}

// Removes ANSI escapes from the string
static std::string
removeAnsiEscapes(const std::string &s) {
    static boost::regex ansiRe("\\033\\[[0-9;]*[mK]");
    return boost::regex_replace(s, ansiRe, "");
}

// Total across the entire histogram
size_t
histogramTotal(const Histogram &h) {
    size_t retval = 0;
    for (auto &node: h)
        retval += node.second;
    return retval;
}

int main(int argc, char *argv[]) {
    initialize(argc, argv);
    if (!gSettings.updateAuthorship.empty()) {
        updateAuthorship(findGitFiles(gSettings.updateAuthorship));
        exit(0);
    }

    FileNames gitFiles = findGitFiles(".");
    initializeFileNameMap(gitFiles);
    std::map<boost::filesystem::path, std::vector<Commit>> allBlame;
    Histogram flawCounts;

    // Read standard input, and for each line recognized as a compiler warning message, obtain information about which author
    // possibly caused the warning.
    FileNames mentionedFiles;
    boost::filesystem::path prevWarningFileName;
    size_t prevWarningLineNumber = 0;
    boost::regex warningRe("(.*?):([0-9]+)(:[0-9]+)?: warning:");
    while (std::cin) {
        std::string line;
        std::getline(std::cin, line);
        std::cout <<line <<"\n";
        line = removeAnsiEscapes(line);
        findMentionedFiles(line, mentionedFiles /*in,out*/, gitFiles);

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

        // We found a warning, so lay some blame. First we need to find the Git file that corresponds to the file name given in
        // the compiler output. This is complicated by the fact that the build system often runs the compiler in different
        // directories than the source code.
        boost::filesystem::path gitFileName = translateToGitFile(warningFileName, gitFiles);
        if (gitFileName.empty()) {
            if (gSettings.debug)
                std::cerr <<"debug: cannot resolve " <<warningFileName <<" to a Git file\n";
            ++flawCounts["unresolved file name"];
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
            ++flawCounts["blame failure"];
            continue;
        }
        const Commit &commit = fileBlame->second[warningLineNumber];
        if (commit.hash.empty()) {
            if (gSettings.debug)
                std::cerr <<"debug: cannot parse blame for " <<gitFileName <<" line " <<warningLineNumber <<"\n";
            ++flawCounts["blame failure"];
            continue;
        }
        std::string endl;
        if (!gSettings.highlight.empty() && gSettings.useColor &&
            (boost::regex_search(commit.name, gSettings.highlight) || boost::regex_search(commit.email, gSettings.highlight))) {
            std::cout <<"\033[30;103m";                 // black on bright yellow
            endl = "\033[0m";
        }
        std::cout <<"blamed on " <<commit.name <<" <" <<commit.email <<"> commit " <<commit.hash <<" from " <<commit.date <<endl <<"\n";
        ++flawCounts[commit.name];
    }

    if (gSettings.debug) {
        std::cout <<"mentioned files:\n";
        for (auto &name: mentionedFiles)
            std::cout <<"\t" <<name <<"\n";
        std::cout <<"mentioned files' directories:\n";
        for (auto &name: directories(mentionedFiles))
            std::cout <<"\t" <<name <<"\n";
    }

    // Show the final histogram.
    if (gSettings.showHistogram && !flawCounts.empty()) {
        std::cout <<"Flaws per author:\n";
        std::cout <<boost::format("\t%5s %10s %10s %s\n") %"Flaws" %"LOC" %"Flaws/MLOC" %"Author";
        std::cout <<"\t----- ---------- ---------- --------------------------------\n";
        std::vector<std::pair<std::string, size_t>> sorted(flawCounts.begin(), flawCounts.end());
        std::sort(sorted.begin(), sorted.end(), [](auto &a, auto &b) { return a.second > b.second; });
        Authorship authorship = readAuthorship();
        Histogram authorLoc = locPerAuthor(authorship, mentionedFiles);
        bool showedRate = false;
        for (auto record: sorted) {
            std::string highlight, endl;
            if (!gSettings.highlight.empty() && gSettings.useColor && boost::regex_search(record.first, gSettings.highlight)) {
                highlight = "\033[30;103m";                 // black on bright yellow
                endl = "\033[0m";
            }
            if (size_t loc = authorLoc[record.first]) {
                size_t flawsPerMillion = std::round(1000000.0 * record.second / loc);
                std::cout <<(boost::format("\t%s%5d %10d %10d %s%s\n")
                             %highlight %record.second %loc %flawsPerMillion %record.first %endl);
                showedRate = true;
            } else {
                std::cout <<boost::format("\t%s%5d %10s %10s %s%s\n") %highlight %record.second %"" %"" %record.first %endl;
            }
        }
        if (showedRate) {
            size_t nSrcFiles = mentionedFiles.size();
            size_t loc = histogramTotal(authorLoc);
            std::cout <<"\tFlaws per million LOC is based on "
                      <<loc <<" line" <<(1 == loc ? "" : "s") <<" of code from "
                      <<nSrcFiles <<" file" <<(1 == nSrcFiles ? "" : "s") <<"\n";
        } else if (authorship.empty()) {
            std::cout <<"\tTo get LOC and flaw rates, run: ";
            if (boost::filesystem::current_path() == gSettings.gitRepo) {
                std::cout <<argv[0] <<" --authorship=. --verbose\n";
            } else {
                std::cout <<"(cd " <<gSettings.gitRepo <<" && " <<argv[0] <<" --authorship=. --verbose)\n";
            }
        }
    }
}
