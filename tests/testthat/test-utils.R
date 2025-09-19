library(testthat)
source("tasks/transferegov/src/R/utils.R")

test_that("build_transferegov_params creates expected tibble", {
  tmp_input <- tempfile(fileext = ".csv")
  tmp_output <- tempfile(fileext = ".csv")
  readr::write_csv(data.frame(id = c("1", "2", "2")), tmp_input)
  params <- build_transferegov_params(tmp_input, tmp_output, "recurso", "id")
  expect_s3_class(params, "tbl_df")
  expect_equal(params$resource, rep("recurso", 2))
  expect_equal(params$key, list(list(id = "eq.1"), list(id = "eq.2")))
  expect_equal(params$perc, c("50%", "100%"))
  expect_equal(params$path_output, rep(tmp_output, 2))
})

test_that("request_transferegov_resource builds correct url", {
  req <- request_transferegov_resource(resource = "foo", params = list(bar = "baz"))
  expect_s3_class(req, "httr2_request")
  expect_equal(req$url$scheme, "https")
  expect_equal(req$url$hostname, "api.transferegov.gestao.gov.br")
  path <- req$url$path
  path_str <- if (length(path) > 1) paste(path, collapse = "/") else path
  expect_true(grepl("transferenciasespeciais/foo$", path_str))
  expect_equal(req$url$query$bar, "baz")
})
