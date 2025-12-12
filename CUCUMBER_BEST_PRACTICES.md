# Cucumber Best Practices for Java Playground Projects

Based on lessons learned from real project implementations, this guide helps avoid common pitfalls when creating Cucumber BDD tests in your Java playground projects.

## Parameter Type Matching

### The Problem

Cucumber expressions use specific parameter types that must match your feature file text exactly.

### Parameter Type Reference

| Type                                     | Pattern                 | Usage                      | Example                          |
| ---------------------------------------- | ----------------------- | -------------------------- | -------------------------------- |
| `{word}`                                 | Single words, no spaces | Names, IDs, keywords       | `When I add user {word}`         |
| `{int}`                                  | Integer numbers         | Counts, ages, iterations   | `When I create {int} items`      |
| `{double}`                               | Decimal numbers         | Measurements, percentages  | `When I set value to {double}`   |
| `{string}`                               | Quoted text with spaces | Full phrases, descriptions | `When I set title to "{string}"` |
| `{byte}`, `{short}`, `{long}`, `{float}` | Numeric variants        | Type-specific numbers      | `When I set timeout to {long}`   |

### ✅ Correct Examples

```java
// Feature file: When I add user john_smith
@When("I add user {word}")
public void addUser(String username) { }

// Feature file: When I create 5 items
@When("I create {int} items")
public void createItems(int count) { }

// Feature file: When I set value to 99.99
@When("I set value to {double}")
public void setValue(double amount) { }

// Feature file: When I set title to "My Project"
@When("I set title to {string}")
public void setTitle(String title) { }
```

### ❌ Common Mistakes

```java
// WRONG: Using {string} for single word
@When("I add user {string}")  // Won't match "john_smith"
public void addUser(String username) { }

// WRONG: Using {word} with spaces
// Feature: When I set title to My Project Title
@When("I set title to {word}")  // Only matches "My", ignores rest
public void setTitle(String title) { }

// WRONG: Forgetting quotes in feature file
// Feature: When I set title to My Project Title (no quotes)
@When("I set title to {string}")  // Won't match unquoted text
public void setTitle(String title) { }
```

## Duplicate Step Definitions

### The Problem

If the same step is defined in multiple step definition classes, Cucumber throws a `DuplicateStepDefinitionException` and all tests fail.

### ❌ What Causes the Error

```java
// src/cucumber/java/.../UserSteps.java
@Then("the user should exist")
public void assertUserExists() {
    // ... verification code
}

// src/cucumber/java/.../AccountSteps.java
@Then("the user should exist")  // ⚠️ DUPLICATE!
public void assertUserExists() {
    // ... same verification
}
```

**Error:** `Duplicate step definitions in UserSteps.assertUserExists() and AccountSteps.assertUserExists()`

### ✅ Solutions

#### Option 1: Single Definition Location

Place the step in ONE step definition class that makes sense:

```java
// src/cucumber/java/.../CommonSteps.java
public class CommonSteps {
    @Then("the user should exist")
    public void assertUserExists() {
        // Single definition used by all scenarios
    }
}
```

#### Option 2: Feature-Specific Variations

Make steps more specific if behavior differs:

```java
// UserSteps.java
@Then("the user account should be active")
public void assertUserActive() { }

// AdminSteps.java
@Then("the admin user should have permissions")
public void assertAdminPermissions() { }
```

### Identifying Duplicates

Run Gradle with verbose output:

```bash
./gradlew cucumber --info 2>&1 | grep -i "duplicate\|exception"
```

## Numeric Type Handling

### The Problem

Depending on the domain, you may need special handling for numeric types like `BigDecimal`, `Long`, or `Integer`.

### ❌ Wrong Approaches

```java
// WRONG: Direct comparison with operators
if (amount > 0) { }           // May fail with BigDecimal
if (count == MAX_VALUE) { }   // Fails with BigDecimal or Long
```

### ✅ Correct Approach with BigDecimal

```java
// For comparisons, use .compareTo()
if (amount.compareTo(BigDecimal.ZERO) > 0) { }       // amount > 0
if (amount.compareTo(new BigDecimal(100)) <= 0) { }  // amount <= 100

// For assertions in tests, use AssertJ
assertThat(result).isEqualByComparingTo(new BigDecimal("99.99"));
```

### ✅ Example: Numeric Calculation

```java
@When("I calculate with multiplier {double}")
public void calculateValue(double multiplier) {
    BigDecimal multiplierBd = new BigDecimal(multiplier);

    // Validation with .compareTo()
    if (multiplierBd.compareTo(BigDecimal.ONE) < 0) {
        throw new IllegalArgumentException("Multiplier must be >= 1");
    }

    // Calculation (example)
    result = baseValue.multiply(multiplierBd)
        .setScale(2, RoundingMode.HALF_UP);
}

@Then("the result should be {double}")
public void assertResult(double expected) {
    // Use AssertJ for cleaner assertions
    assertThat(result)
        .isEqualByComparingTo(new BigDecimal(expected));
}
```

## Step Definition Organization

### Project Structure Best Practices

```
src/cucumber/java/
└── com/example/myproject/
    ├── steps/
    │   ├── UserSteps.java          # User-related steps
    │   ├── OrderSteps.java         # Order-related steps
    │   ├── PaymentSteps.java       # Payment-related steps
    │   ├── CommonSteps.java        # Shared/common steps
    │   └── SetupSteps.java         # Setup/fixture steps
    └── CucumberTestRunner.java

src/cucumber/resources/
├── user.feature                    # User feature
├── order.feature                   # Order feature
├── payment.feature                 # Payment feature
└── common.feature                  # Common scenarios (optional)
```

### Guidelines

1. **One step class per feature file** (when feasible)

   - `user.feature` → `UserSteps.java`
   - `order.feature` → `OrderSteps.java`

2. **Share common steps strategically**

   - Authentication setup: `AuthSteps.java`
   - Common assertions: `CommonSteps.java`
   - Test fixtures: `SetupSteps.java`
   - Avoid unnecessary duplication

3. **Clear naming conventions**

   - Class names reflect domain: `InventorySteps`, `ReportSteps`
   - Method names describe the action: `createUser()`, `submitOrder()`

4. **Avoid cross-cutting concerns**
   - Don't define login in every step class
   - Create `AuthSteps.java` for authentication-related steps

## Testing Tools & Dependencies

### Essential for Playground Projects

```gradle
// JUnit 5 - Test framework
testImplementation 'org.junit.jupiter:junit-jupiter-api:5.10.1'
testImplementation 'org.junit.jupiter:junit-jupiter-params:5.10.1'

// AssertJ - Fluent assertions
testImplementation 'org.assertj:assertj-core:3.24.2'
cucumberImplementation 'org.assertj:assertj-core:3.24.2'

// Cucumber - BDD testing
cucumberImplementation 'io.cucumber:cucumber-java:7.14.1'
cucumberImplementation 'io.cucumber:cucumber-junit-platform-engine:7.14.1'
```

### AssertJ Fluent Assertions (Recommended)

```java
// Instead of: assertTrue(isActive);
assertThat(isActive).isTrue();

// Instead of: assertTrue(list.contains(item));
assertThat(items).contains("apple", "banana");

// Instead of: assertNull(value);
assertThat(value).isNull();

// Instead of: assertEquals(status, "ACTIVE");
assertThat(status).isEqualTo("ACTIVE");

// For numeric comparisons
assertThat(count).isGreaterThan(0).isLessThan(100);
```

## Running Tests Effectively

### Individual Test Runs (Clearer Output)

```bash
# Run only JUnit unit tests
./gradlew test

# Run only Cucumber BDD tests
./gradlew cucumber

# Run both sequentially (recommended)
./gradlew test cucumber
```

### Full Verification (All Tasks)

```bash
# Runs all verification tasks
# Takes longer and output may be less clear
./gradlew check
```

**Note:** The `check` task may appear to pause between tasks. This is normal - subsequent tasks are queued and will execute.

## Debugging Failed Tests

### View Detailed Output

```bash
# Show full stack traces
./gradlew cucumber --info

# Show individual step details
./gradlew cucumber -d

# Filter for specific test
./gradlew test --info | grep "MyFeatureSteps"
```

### Review Test Reports

After tests complete, open reports in browser:

- **JUnit:** `build/reports/tests/test/index.html`
- **Cucumber:** `build/reports/tests/cucumber/index.html`

### Common Debugging Patterns

```java
// Add debug logging in step definitions
@When("I process data with {word} mode")
public void processData(String mode) {
    System.out.println("DEBUG: Processing mode = " + mode);
    // ... actual step code
}

// Use AssertJ for better error messages
assertThat(result)
    .as("processing failed for mode: %s", mode)
    .isNotNull();
```

## Quick Reference: Step Definition Checklist

Before committing your step definitions:

- ✅ Parameter types match feature file text (`{word}`, `{int}`, `{double}`, `{string}`)
- ✅ Each step is defined only once globally across all step classes
- ✅ Numeric operations use appropriate type handling (`.compareTo()` for BigDecimal)
- ✅ Assertions use AssertJ fluent API
- ✅ Step classes are organized by feature/domain
- ✅ Feature files and step classes use consistent naming
- ✅ Shared steps are in dedicated classes (no duplication)
- ✅ Step definitions include descriptive comments where needed
- ✅ Test reports are checked after test failures
- ✅ `./gradlew test cucumber` used instead of `./gradlew check` for local development

## Additional Resources

- [Cucumber Java Documentation](https://cucumber.io/docs/cucumber/cucumber-expressions/)
- [AssertJ Assertions Guide](https://assertj.github.io/assertj-core-features-highlight.html)
- [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/)
- [Cucumber Best Practices](https://cucumber.io/docs/bdd/)
