/* version.cxx -- version number */
#include "xs.hxx"
#include "git_date.hxx"
#include "git_hash.hxx"
#include "git_url.hxx"
const char * const version = "xs 1.1 (git: " GIT_DATE "; " GIT_HASH " @ " GIT_URL ")";
