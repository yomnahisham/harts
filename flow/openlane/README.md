# OpenLane configuration (HARTS)

This flow targets **`hw_scheduler_top`** as a SKY130 HD macro. Values below mirror a typical Silicon Sprint / LibreLane-style workshop setup, adapted for this RTL (not the AES wrapper).

## Global routing, post-GRT repair, and antenna

### Global routing (GRT)

Global routing assigns a coarse routing plan per net (G-cells); no final shapes yet. That plan yields better **R/C estimates** for timing. We keep LibreLane defaults for **`GRT_ADJUSTMENT`** (0.3), **`GRT_ALLOW_CONGESTION`** (false), **`GRT_OVERFLOW_ITERS`** (50), and layer span **`RT_MIN_LAYER`** / **`RT_MAX_LAYER`** except where noted.

### `RT_MAX_LAYER`: `met4`

The HD stack exposes met1–met5. **`RT_MAX_LAYER`: `"met4"`** keeps **signal** routing off **met5**, same idea as the Caravel user-project workshop: a top-level wrapper often straps **power on met5**; a macro that uses met5 for signals risks shorts or painful merge DRC after integration. Use met5 only if you control the full chip top and PDN plan.

### Post-GRT design repair

**`RUN_POST_GRT_DESIGN_REPAIR`**: `true` enables **RepairDesignPostGRT** so the resizer uses **GRT-aware** parasitics (not placement-only estimates) for buffer insertion / gate resizing, similar in spirit to post-CTS repair but with routing context.

**`DESIGN_REPAIR_MAX_SLEW_PCT`** / **`DESIGN_REPAIR_MAX_CAP_PCT`** (30): tighter slew/cap margins for those repair passes than the workshop’s default **10**% GRT repair slack keys—already in use for this block.

### Antenna checks and repair

After GRT, **CheckAntennas** uses physical route intent so antenna ratios (metal vs. gate oxide) can be evaluated. **`GRT_ANTENNA_REPAIR_ITERS`**: **10** (workshop-style; default in docs is often 3) and **`GRT_ANTENNA_REPAIR_MARGIN`**: **15** (over-fix vs. default **10**%) give extra headroom before **DRT** can worsen ratios slightly.

**`DIODE_ON_PORTS`**: **`"both"`** inserts antenna diodes on **input and output** ports, which helps macros with wide buses (here: e.g. SPI and parallel control) where diode insertion is often more effective than jumper-only repair alone.

### Detailed routing (DRT)

TritonRoute turns the GRT plan into legal met/via geometry.

**Clock NDR and this flow’s ECO substitution:** `meta.substituting_steps` runs **DetailedRouting**, then **InsertECOBuffers**, then **DetailedRouting** again. If `config.json` also sets **`NON_DEFAULT_RULES`** / **`DRT_ASSIGN_NDR`**, the first DRT pass creates a named rule (for example `clkndr`) in the ODB; the second pass tries `create_ndr` again and OpenROAD fails with **`[ODB-1005] NonDefaultRule … already exists`**. This project therefore relies on **`CTS_APPLY_NDR`** only for clock NDR (no duplicate named rules across two DRT steps).

---

## Clock non-default routing (NDR)

Clock nets get non-default spacing/width from **`CTS_APPLY_NDR`** during CTS (`clock_tree_synthesis … -apply_ndr …`), not from separate DRT-only rules in this config.

### `CTS_APPLY_NDR`: `half` vs `full`

OpenLane’s **default** for `CTS_APPLY_NDR` is **`half`**. This project sets it explicitly to **`half`** to match typical workshop-style flows.

| Value | Behavior |
|--------|----------|
| **`half`** | Applies the 2× spacing (and associated NDR) to clock nets **except leaf-level** segments. Main branches get extra crosstalk margin; dense logic near sinks keeps thinner leaves to limit routing congestion. |
| **`full`** | Extends the same NDR to the **entire** clock tree, **including leaves**. Stronger isolation everywhere at the cost of more track usage near standard cells. |

Using **`full`** is a valid choice for explanation or aggressive clock shielding, but it is **not** the usual workshop default; **`half`** is the balanced default.

### SKY130 HD nominal metal 2 (from the technology LEF)

Default routing dimensions for SkyWater 130 nm **HD** are in the nominal tech LEF, for example:

```text
libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
```

Exact path depends on your PDK install. One example layout (Ciel):

```text
~/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130B/
  libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
```

The **met2** layer (common default for **vertical** clock routing) includes:

```text
LAYER met2
  TYPE ROUTING ;
  DIRECTION VERTICAL ;
  PITCH 0.46 ;
  WIDTH 0.14 ;
  SPACINGTABLE
     PARALLELRUNLENGTH 0
     WIDTH 0   0.14
     WIDTH 3   0.28 ;
```

CTS **`apply_ndr`** targets roughly **2×**-style spacing on clock branches (see OpenROAD CTS docs for the exact mapping), i.e. a stronger crosstalk margin on **met2** at the cost of more routing tracks, with promotion to upper metals as the tree needs.

### Related keys in `config.json`

- **`CTS_APPLY_NDR`**: How aggressively CTS applies NDR to the clock tree (`half` here: non-leaf / upper levels, not every leaf segment).

If you drop the ECO substitution so only **one** DetailedRouting runs, you may add **`NON_DEFAULT_RULES`** and **`DRT_ASSIGN_NDR`** again for a custom named rule without hitting ODB-1005.
