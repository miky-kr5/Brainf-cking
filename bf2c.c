#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define EXIT_NO_INPUT 4

static const char * BF_HEADER = "#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n\nstatic unsigned char tape[30000];\nstatic unsigned int tape_ptr = 0;\n\nint main(void) {\n\tmemset(tape, 0, 30000 * sizeof(unsigned char));\n";
static const char * BF_FOOTER = "\n\treturn EXIT_SUCCESS;\n}\n";

static inline void print_tabs (FILE * f, unsigned int t) {
  int i;
  for (i = 0; i < t; i++)
    fputc('\t', f);
}

int main (int argc, char **argv) {
  FILE *       f;  /* The input file. */
  FILE *       o;  /* The output file. */ 
  unsigned int i;  /* The current file being processed. */
  unsigned int t;  /* Tab level. */
  char         c;  /* Current BF instruction. */
  char * out_file; /* Output file name. */

  if (argc == 1) {
    /* There must be at leas one input file. */
    fprintf (stderr, "%s: fatal error: no input files\n", argv[0]);
    return EXIT_NO_INPUT;

  } else {

    for (i = 1; i < argc; i++) {
      /* Try to open the input and output files. */
      out_file = (char *) calloc (strlen(argv[i]) + 3, sizeof(char));
      if (out_file == NULL) {
	fprintf (stderr, "Could not allocate memory for output file name\n");
	return EXIT_FAILURE;

      } else {
	sprintf(out_file, "%s.c", argv[i]);
	f = fopen (argv[i], "r");
	o = fopen (out_file, "w");

	if (f == NULL || o == NULL) {
	  fprintf (stderr, "Failed to open %s or %s\n", argv[i], out_file);
	  continue;

	} else {
	  t = 1;

	  /* Print boilerplate. */
	  fprintf(o, "%s", BF_HEADER);

	  /* If the file opened, then read characters from it one by one. */
	  while ((c = fgetc (f)) != EOF) {

	    /* Proccess the character. */
	    switch (c) {

	    case '.':
	      /* BF output instruction. */
	      print_tabs (o, t);
	      fprintf(o, "putchar((int)tape[tape_ptr]);\n");
	      print_tabs (o, t);
	      fprintf(o, "fflush(stdout);\n");
	      break;

	    case ',':
	      /* BF input instruction. */
	      print_tabs (o, t);
	      fprintf(o, "tape[tape_ptr] = (unsigned char)getchar();\n");
	      break;

	    case '+':
	      /* BF tape increment instruction. */
	      print_tabs (o, t);
	      fprintf(o, "tape[tape_ptr]++;\n");
	      break;

	    case '-':
	      /* BF Tape decrement instruction. */
	      print_tabs (o, t);
	      fprintf(o, "tape[tape_ptr]--;\n");
	      break;

	    case '>':
	      /* BF move to next cell instruction. */
	      print_tabs (o, t);
	      fprintf(o, "tape_ptr = (tape_ptr + 1) %% 30000;\n");
	      break;

	    case '<':
	      /* BF move to previous cell instruction. */
	      print_tabs (o, t);
	      fprintf(o, "tape_ptr = (tape_ptr == 0) ? 29999: tape_ptr - 1;\n");
	      break;

	    case '[':
	      /* BF open loop instruction. */
	      print_tabs (o, t++);
	      fprintf(o, "while (tape[tape_ptr]) {\n");
	      break;

	    case ']':
	      /* BF close loop instruction. */
	      print_tabs (o, --t);
	      fprintf(o, "}\n");
	      break;

	    default:
	      continue;
	    } /* switch(c) */
	  } /* while(c = fgetc(f)) */

	  /* Print boilerplate. */
	  fprintf(o, "%s", BF_FOOTER);

	  /* Done with this file. */
	  fclose (f);
	}
      }
    }
  }

  return 0;
}
