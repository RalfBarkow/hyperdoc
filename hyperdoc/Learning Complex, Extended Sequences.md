# Learning Complex, Extended Sequences Using the Principle of History Compression

This is **not just a bibliography entry**. It is a bibliography entry **plus a priority claim**.

The bibliographic core is straightforward: the author is **Jürgen Schmidhuber**; the paper is **“Learning Complex, Extended Sequences Using the Principle of History Compression”**; it appeared in **Neural Computation** **4(2):234–242** in **1992**; and it was based on **Technical Report FKI-148-91** from **TUM, 1991**. ([MIT Press Direct][1])

The rest of the note is advocacy language, not neutral reference prose. In particular, phrases like **“First working deep learner,” “overcoming the vanishing gradient problem,”** and **“the P in ChatGPT”** are not standard bibliographic descriptors. They are part of Schmidhuber’s own retrospective framing of this line of work. His homepage explicitly uses the slogan that 1991 work provided **“the P in ChatGPT,”** which shows where that wording comes from. ([IDSIA][2])

A more neutral historical reading would be: this paper is an **early hierarchical recurrent / predictive coding / history-compression approach** that later retrospectives connect to deep learning and pre-training. But the stronger claim that it already **“overcame the vanishing gradient problem”** is contestable. Standard accounts treat the vanishing-gradient problem as being formally analyzed by **Hochreiter** in 1991/1998, with **LSTM** proposed in 1997 as a solution; and broader survey papers usually place the major breakthrough for **effective unsupervised pre-training of deep architectures** in the **2006** deep belief net era. ([Institute of Bioinformatics][3])

The **teacher/student distillation** part is similar: it is fair to say Schmidhuber later interprets the **chunker/automatizer** setup as an early form of neural distillation or compression, and that language does appear in his later retrospectives. But that is again a **retrospective interpretation**, not the neutral consensus way this 1992 paper is usually cited. ([arXiv][4])

A clean, neutral rewrite would be:

> **Schmidhuber, J. (1992).** *Learning Complex, Extended Sequences Using the Principle of History Compression.* **Neural Computation, 4**(2), 234–242. Based on Technical Report **FKI-148-91**, Technical University of Munich, 1991. The paper presents an early hierarchical recurrent approach to sequence learning based on predictive coding and history compression. ([MIT Press Direct][1])

And if you want the **annotated** version without the self-promotional overreach:

> **Schmidhuber, J. (1992).** *Learning Complex, Extended Sequences Using the Principle of History Compression.* **Neural Computation, 4**(2), 234–242. Based on TR FKI-148-91, TUM, 1991. An early hierarchical recurrent architecture for long-range sequence modeling via predictive coding and history compression; later retrospectives link it to themes of unsupervised pre-training and model compression. ([MIT Press Direct][1])

The typo **“CHatGPT”** should also be fixed to **“ChatGPT.”**

[1]: https://direct.mit.edu/neco/article/4/2/234/5634/Learning-Complex-Extended-Sequences-Using-the?utm_source=chatgpt.com "Learning Complex, Extended Sequences Using the ..."
[2]: https://www.idsia.ch/~juergen?utm_source=chatgpt.com "Juergen Schmidhuber's home page"
[3]: https://www.bioinf.jku.at/publications/older/2304.pdf?utm_source=chatgpt.com "the vanishing gradient problem during learning recurrent ..."
[4]: https://arxiv.org/pdf/1802.08864?utm_source=chatgpt.com "arXiv:1802.08864v1 [cs.AI] 24 Feb 2018"
