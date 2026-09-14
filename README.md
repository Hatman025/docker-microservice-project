# Hands-On DevSecOps Lab: GitHub Actions — Step Outputs vs Job Outputs

| | |
|---|---|
| **Difficulty** | Beginner to Intermediate |
| **Topic** | GitHub Actions Outputs |
| **Estimated Time** | 30–45 minutes |

---

## 1. Objective

By the end of this lab, you should be able to:

1. Create a step output using `$GITHUB_OUTPUT`.
2. Access a step output from another step in the same job.
3. Convert a step output into a job output.
4. Pass a job output from one job to another job.
5. Understand the difference between:
   - `steps.<step_id>.outputs.<output_name>`
   - `needs.<job_id>.outputs.<output_name>`
6. Use job outputs to control what happens in a DevSecOps pipeline.

---

## 2. Scenario

You are working as a DevSecOps Engineer.

Your team has a CI/CD pipeline with two jobs:

```
BUILD
  ↓
SECURITY
```

The `BUILD` job creates a Docker image tag.

The `SECURITY` job needs to know which image was created so that it can scan that image.

For this lab, we will simulate the Docker build and security scan using `echo` commands. The goal is to understand how data moves between steps and jobs.

---

## 3. What You Need to Build

Your workflow should look like this:

```
┌──────────────────────────┐
│       BUILD JOB          │
│                           │
│ Step 1                    │
│ Generate image tag        │
│          ↓                │
│ Step 2                    │
│ Display image tag         │
└────────────┬──────────────┘
             │
             │ Job Output
             │ image_tag
             ▼
┌──────────────────────────┐
│      SECURITY JOB         │
│                           │
│ Receive image_tag         │
│          ↓                │
│ Scan image                │
└──────────────────────────┘
```

---

## 4. Requirements

Create this file:

```
.github/workflows/outputs-lab.yml
```

Your workflow must contain:

- **Job 1:** `build`
- **Job 2:** `security`

The `security` job must depend on the `build` job.

---

## 5. Task 1: Create the Build Job

Create a job called:

```
build:
```

It should run on:

```
ubuntu-latest
```

---

## 6. Task 2: Generate a Step Output

Inside the `build` job, create a step called:

```
Generate Image Tag
```

Give the step this ID:

```
generate
```

The step must create an output called:

```
image_tag
```

The value should be:

```
app:v1.0
```

Use `$GITHUB_OUTPUT`.

**Hint:** You need something similar to:

```bash
echo "name=value" >> "$GITHUB_OUTPUT"
```

Your output should therefore contain:

```
image_tag=app:v1.0
```

---

## 7. Task 3: Use the Step Output

Create a second step called:

```
Display Image Tag
```

This step must display:

```
The image is app:v1.0
```

You must retrieve the value using the step output syntax:

```
steps.<step_id>.outputs.<output_name>
```

Remember:
- step ID = `generate`
- output name = `image_tag`

So you need to construct the correct expression yourself.

---

## 8. Task 4: Create a Job Output

Now comes the important part.

The `security` job is a different job. Therefore, it cannot directly use:

```
steps.generate.outputs.image_tag
```

from the `build` job.

You must expose the step output as a job output.

Create a job output called:

```
image_tag
```

The job output should receive its value from:

```
steps.generate.outputs.image_tag
```

Your structure should look conceptually like:

```yaml
build:
  outputs:
    image_tag: ...
```

Complete the expression yourself.

---

## 9. Task 5: Create the Security Job

Create a second job called:

```
security
```

It must depend on the `build` job. Use:

```
needs:
```

The relationship should be:

```
build
  ↓
security
```

---

## 10. Task 6: Retrieve the Job Output

Inside the `security` job, create a step called:

```
Security Scan
```

Print:

```
Scanning image: app:v1.0
```

This time you cannot use:

```
steps.generate.outputs.image_tag
```

because `generate` belongs to another job.

Instead, use:

```
needs.<job_id>.outputs.<output_name>
```

You know:
- job ID = `build`
- output name = `image_tag`

Construct the correct expression.

---

## 11. Expected Result

When you run the workflow, you should see output similar to:

```
The image is app:v1.0
Scanning image: app:v1.0
```

The important thing is that the value `app:v1.0` was created in one step and eventually consumed by a step in another job.

---

## 12. Your Challenge

Before looking at the solution, try to complete the workflow yourself. You should be able to answer these questions:

**Question 1**
What is the step output?

______________________________________

**Question 2**
What syntax is used to access a step output?

______________________________________

**Question 3**
What is the job output?

______________________________________

**Question 4**
What syntax is used to access a job output from another job?

______________________________________

**Question 5**
Why can't the security job directly use `steps.generate.outputs.image_tag`?

______________________________________

---

## 13. Solution

After attempting the lab, compare your answer with this solution.

```yaml
name: Step and Job Outputs Lab
on:
  workflow_dispatch:

jobs:
  # =================================
  # JOB 1: BUILD
  # =================================
  build:
    runs-on: ubuntu-latest
    # Expose the step output as a job output
    outputs:
      image_tag: ${{ steps.generate.outputs.image_tag }}
    steps:
      # -----------------------------
      # STEP 1
      # -----------------------------
      - name: Generate Image Tag
        id: generate
        run: |
          echo "image_tag=app:v1.0" >> "$GITHUB_OUTPUT"

      # -----------------------------
      # STEP 2
      # -----------------------------
      - name: Display Image Tag
        run: |
          echo "The image is ${{ steps.generate.outputs.image_tag }}"

  # =================================
  # JOB 2: SECURITY
  # =================================
  security:
    needs: build
    runs-on: ubuntu-latest
    steps:
      # -----------------------------
      # STEP 1
      # -----------------------------
      - name: Security Scan
        run: |
          echo "Scanning image: ${{ needs.build.outputs.image_tag }}"
```

---

## 14. Understand the Data Flow

This is the most important part of the lab.

Step 1 creates the value with `id: generate` and:

```bash
echo "image_tag=app:v1.0" >> "$GITHUB_OUTPUT"
```

This creates `steps.generate.outputs.image_tag`.

So:

```
Generate Image Tag
       │
       ▼
steps.generate.outputs.image_tag
```

---

## 15. The Build Job Exposes the Output

This section:

```yaml
outputs:
  image_tag: ${{ steps.generate.outputs.image_tag }}
```

takes the step output and exposes it as a job output.

Think of it as:

```
STEP OUTPUT
     │
     ▼
JOB OUTPUT
```

The job output is now:

```
build.outputs.image_tag
```

---

## 16. The Security Job Receives It

The `security` job has:

```yaml
needs: build
```

Therefore, it can access outputs from the `build` job. It uses:

```
needs.build.outputs.image_tag
```

So the complete flow is:

```
BUILD JOB
Generate Image Tag
       │
       ▼
steps.generate.outputs.image_tag
       │
       ▼
jobs.build.outputs.image_tag
       │
       ▼
SECURITY JOB
needs.build.outputs.image_tag
       │
       ▼
Security Scan
```

---

## 17. The Main Difference

### Step Output

A step output is mainly used for communication **within the same job**.

```
Step A
  ↓
Step B
  ↓
Step C
```

**Reference:**
```
steps.<step_id>.outputs.<output_name>
```

**Example:**
```
steps.generate.outputs.image_tag
```

### Job Output

A job output allows information to move **from one job to another**.

```
Job A
  ↓
Job B
```

**Reference:**
```
needs.<job_id>.outputs.<output_name>
```

**Example:**
```
needs.build.outputs.image_tag
```

---

## 18. The Rule to Remember

| Scope | Syntax | Example |
|---|---|---|
| Same job | `steps` | `steps.generate.outputs.image_tag` |
| Different job | `needs` | `needs.build.outputs.image_tag` |

A simple memory trick:

```
STEP → STEP  = steps
JOB  → JOB   = needs
```

---

## 19. DevSecOps Extension

Once the basic lab works, modify it.

Add a security result to the `security` job:

```
scan_result=PASS
```

Make it a step output. Then expose it as a job output.

Finally, create a third job:

```
deploy
```

Your pipeline should become:

```
BUILD
  │
  │ image_tag
  ▼
SECURITY
  │
  │ scan_result
  ▼
DEPLOY
```

The deployment should only happen when:

```
scan_result == PASS
```

This will be your next level because you will practice: **step outputs → job outputs → security gates → deployment conditions.**
