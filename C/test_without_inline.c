#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <windows.h>

const int STR_LEN = 2048;

// === Генерация случайных строк ===
void randStr(char* s) {
    for (int i = 0; i < STR_LEN; i++) {
        s[i] = (rand() % 2 == 0)
            ? ('A' + rand() % 26)
            : ('a' + rand() % 26);
    }
    s[STR_LEN] = '\0';
}

// === Тестируемые функции ===
void obviouseUpperCase(char *str) {
    for (size_t i = 0; str[i] != '\0'; ++i)
        if (str[i] >= 'a' && str[i] <= 'z')
            str[i] -= 32;
}

void branchlessUpperCase1(char *str) {
    for (size_t i = 0; str[i] != '\0'; ++i)
        str[i] = (str[i] * !(str[i] >= 'a' && str[i] <= 'z')) +
                 (str[i] - 32) * (str[i] >= 'a' && str[i] <= 'z');
}

void branchlessUpperCase2(char *str) {
    for (size_t i = 0; str[i] != '\0'; ++i)
        str[i] -= 32 * (str[i] >= 'a' && str[i] <= 'z');
}

// === Служебные структуры ===
typedef void (*test_func_t)(char *);
struct TestCase {
    const char *name;
    test_func_t func;
    long long cycles;
};

// === Вспомогательные функции ===
char **makeList(int count) {
    char **list = malloc(count * sizeof(char *));
    if (!list) return NULL;

    for (int i = 0; i < count; ++i) {
        list[i] = malloc(STR_LEN + 1);
        if (!list[i]) {
            for (int j = 0; j < i; ++j) free(list[j]);
            free(list);
            return NULL;
        }
        randStr(list[i]);
    }
    return list;
}

void freeList(char **list, int count) {
    for (int i = 0; i < count; ++i)
        free(list[i]);
    free(list);
}

void warmUp(const char *orig) {
    size_t len = strlen(orig);
    char *buf = malloc(len + 1);
    if (!buf) return;

    for (int i = 0; i < 1000; ++i) {
        memcpy(buf, orig, len + 1);
        obviouseUpperCase(buf);
        branchlessUpperCase1(buf);
        branchlessUpperCase2(buf);
    }
    free(buf);
}

// === Измерение одной функции ===
void test_function(struct TestCase *test, int iterations) {
    char **list = makeList(iterations);
    if (!list) return;
    test_func_t func = test->func;

    LARGE_INTEGER start, end, freq;
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&start);

    for (int i = 0; i < iterations; ++i)
        func(list[i]);

    QueryPerformanceCounter(&end);
    freeList(list, iterations);

    test->cycles = end.QuadPart - start.QuadPart;
    test->cycles = (test->cycles * 1000000000LL) / freq.QuadPart; // в наносекундах
}

// === Печать результатов ===
void print_results(struct TestCase *tests, int num, int iterations) {
    printf("\n=== РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ ===\n");
    printf("%-20s %-30s %-15s\n", "Функция", "Время (нано сек)", "Время/вызов");
    printf("-----------------------------------------------\n");

    long long min = tests[0].cycles;
    for (int i = 1; i < num; ++i)
        if (tests[i].cycles < min)
            min = tests[i].cycles;

    for (int i = 0; i < num; ++i) {
        double per_call = (double)tests[i].cycles / iterations;
        double rel = (double)tests[i].cycles / min;
        printf("%-20s %-15lld %-10.2f (x%.3f)\n",
               tests[i].name,
               tests[i].cycles,
               per_call,
               rel);
    }
    printf("\n");
}

// === main ===
int main(void) {
    SetConsoleOutputCP(CP_UTF8);
    srand((unsigned)time(NULL));

    const int ITERATIONS = 1000;

    const char *orig = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    struct TestCase tests[] = {
        {"Obviouse    ", obviouseUpperCase, 0},
        {"Branchless 1", branchlessUpperCase1, 0},
        {"Branchless 2", branchlessUpperCase2, 0}
    };
    int num_tests = sizeof(tests) / sizeof(tests[0]);

    printf("\nПрогрев кэша...\n");
    warmUp(orig);

    printf("Запуск тестов (%d итераций)...\n", ITERATIONS);
    for (int i = 0; i < num_tests; ++i)
        test_function(&tests[i], ITERATIONS);

    print_results(tests, num_tests, ITERATIONS);
    return 0;
}
