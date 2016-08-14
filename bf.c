#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define EXIT_NO_INPUT 4

#define TAPE_SIZE 30000
#define MAX_LOOPS 1024

static unsigned char tape[TAPE_SIZE]; /* BF memory cells. */
static long loop_stack[MAX_LOOPS];    /* Loop stack. */
static unsigned int tape_ptr = 0;     /* Current tape position. */
static unsigned int loop_ptr = 0;     /* Loop stack top. */

int
main (int argc, char **argv) {
  FILE *       f;    /* The input file. */  
  unsigned int i;    /* The current file being processed. */
  unsigned int l;    /* A counter for looping. */
  unsigned int done; /* Boolean for looping. */
  char c;            /* Current BF instruction. */

  if (argc == 1) {
    /* There must be at leas one input file. */
    fprintf (stderr, "%s: fatal error: no input files\n", argv[0]);
    return EXIT_NO_INPUT;

  } else {

    /* Process all input files. */
    for (i = 1; i < argc; i++) {
      /* Reset everything. */
      memset (tape, 0, TAPE_SIZE * sizeof (unsigned char));
      memset (loop_stack, 0, MAX_LOOPS * sizeof (long));
      l = 0;
      c = 'a';

      /* Try to open the input file. */
      f = fopen (argv[i], "r");

      if (f == NULL) {
	fprintf (stderr, "Failed to open %s\n", argv[1]);
	continue;

      } else {

	/* If the file opened, then read characters from it one by one. */
	while ((c = fgetc (f)) != EOF) {

	  /* Proccess the character. */
	  switch (c) {

	  case '.':
	    /* BF output instruction. */
	    putchar (tape[tape_ptr]);
	    fflush (stdout);
	    break;

	  case ',':
	    /* BF input instruction. */
	    tape[tape_ptr] = (unsigned char) getchar ();
	    break;

	  case '+':
	    /* BF tape increment instruction. */
	    tape[tape_ptr]++;
	    break;

	  case '-':
	    /* BF Tape decrement instruction. */
	    tape[tape_ptr]--;
	    break;

	  case '>':
	    /* BF move to next cell instruction. */
	    tape_ptr = (tape_ptr + 1) % TAPE_SIZE;
	    break;

	  case '<':
	    /* BF move to previous cell instruction. */
	    tape_ptr = (tape_ptr == 0) ? TAPE_SIZE - 1 : tape_ptr - 1;
	    break;

	  case '[':
	    /* BF open loop instruction. */
	    /* Check if the program has reached the max supported number of open loops. */
	    if (loop_ptr == MAX_LOOPS) {
	      /* Fail if it has. */
	      fprintf (stderr,
		       "%s: Fatal error in %s: max number of nested loops reached\n",
		       argv[0], argv[i]);
	      goto skip;

	    } else {

	      /* Check if there is something on the tape. */
	      if (tape[tape_ptr] != 0) {
		/* If there is, then store the instruction's position on the file
		   so that the program car return to it at the loop's end. */
		loop_stack[loop_ptr] = ftell (f);
		loop_ptr++;

	      } else {

		/* If there is nothing on the tape, then search for the corresponding loop
		   end instruction. */
		done = 0;
		while (!done) {
		  /* Read characters from the file until a [, ] or EOF, whichever happens
		     first. */
		  c = fgetc (f);

		  switch(c) {
		  case EOF:
		    /* Skip the file on EOF. */
		    fprintf (stderr, "%s: Fatal error in %s: premature EOF\n", argv[0], argv[1]);
		    goto skip;
		    break;

		  case '[':
		    /* If a loop opens, then increase the nested loops counter. */
		    l++;
		    break;

		  case ']':
		    /* If a ] instruction is found, */
		    if (l > 0)
		      l--;
		    else
		      done = 1;
		    break;
		  } /* switch(c) */
		} /* while(!done) */
	      } /* else (tape[tape_ptr] == 0) */
	    } /* else (loop_ptr < MAX_LOOPS) */
	    break;

	  case ']':
	    /* BF close loop instruction. */
	    /* Check if there is something on the tape. */
	    if (tape[tape_ptr] != 0)
	      /* If there is, then jump back to the corresponding ] instruction. */
	      fseek (f, loop_stack[loop_ptr - 1], SEEK_SET);
	    else
	      /* If there is nothing, then remove the loop from the stack and continue. */
	      loop_ptr--;
	    break;

	  default:
	    continue;
	  } /* switch(c) */
	} /* while(c = fgetc(f)) */

      skip:
	/* Done with this file. */
	fclose (f);
      } /* else (f != NULL) */
    } /* for(i = 1 to argc - 1) */
  } /* else (argc > 1) */

  return EXIT_SUCCESS;
}
